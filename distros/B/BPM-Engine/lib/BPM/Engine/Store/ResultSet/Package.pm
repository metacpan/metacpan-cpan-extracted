package BPM::Engine::Store::ResultSet::Package;
BEGIN {
    $BPM::Engine::Store::ResultSet::Package::VERSION   = '0.01';
    $BPM::Engine::Store::ResultSet::Package::AUTHORITY = 'cpan:SITETECH';    
    }

use namespace::autoclean;
use Moose;
use MooseX::NonMoose;
use Scalar::Util qw/blessed/;
use BPM::Engine::Util::XPDL ':all';
use BPM::Engine::Exceptions qw/throw_model throw_store/;
extends 'DBIx::Class::ResultSet';

my %APPMAP = ();

sub debug {
    #my @caller = caller(0); warn $_[0] . ' at line ' . $caller[2] . "\n";
    }

sub create_from_xml {
    my ($self, $arg) = @_;

    $arg = xml_hash($arg) unless(ref($arg) eq 'HASH');
    
    return $self->_create_from_hash($arg);
    }

sub create_from_xpdl {
    my ($self, $arg) = @_;

    $arg = xpdl_hash($arg) unless(ref($arg) eq 'HASH');
    
    return $self->_create_from_hash($arg);
    }

sub _create_from_hash {
    my ($self, $args) = @_;

    %APPMAP = ();
    my $schema = $self->result_source->schema;
    
    my $create_txn = sub {
        #-- main element: Package
        my $entry = $self->create( {
            package_uid => $args->{Id},
            version     => '1.0',
            });
        $entry->package_name($args->{Name}) if($args->{Name});

        #-- element: PackageHeader (required)
        _import_packhead($entry, $args->{PackageHeader}) 
            if $args->{PackageHeader};

        #-- element: RedefinableHeader
        _import_redefhead($entry, $args->{RedefinableHeader})
            if $args->{RedefinableHeader};

        #-- element: ConformanceClass
        $entry->graph_conformance($args->{ConformanceClass}->{GraphConformance}) 
            if ($args->{ConformanceClass});

        #-- element: Script
        #-- element: ExternalPackages
        #-- element: TypeDeclarations

        #-- element: Participants
        _import_participants($entry, $args->{Participants}->{Participant}) 
            if $args->{Participants};

        #-- element: Applications
        _import_applications($entry, $args->{Applications}->{Application}) 
            if $args->{Applications};

        #-- elements: DataFields, ExtendedAttributes, Formal/ActualParameters
        if($args->{Artifacts} && $args->{Artifacts}->{seq_Artifact}) {
            $args->{Artifacts}->{Artifact} = [
                map { $_->{Artifact} } 
                grep { $_->{Artifact}->{ArtifactType} eq 'DataObject' }
                @{ $args->{Artifacts}->{seq_Artifact} }
                ];
            delete $args->{Artifacts}->{seq_Artifact};
            #warn Dumper($args->{Artifacts});
            }
        _set_elements($entry, $args);

        #-- element: WorkflowProcesses
        _import_processes($entry, $args->{WorkflowProcesses}->{WorkflowProcess}) 
            if $args->{WorkflowProcesses};
        $entry->update();

        return $entry;
        };

    my $row;
    eval { $row = $schema->txn_do($create_txn); };
    if(my $err = $@) {
        throw_store error => "StoreError $err" if(ref($err));
        throw_model error => 'ModelError' . $err;
        }

    return $row;
    }

sub _import_packhead {
    my ($entry, $args) = @_;

    my %columns = (
        description           => 'Description',
        specification_version => 'XPDLVersion',
        vendor                => 'Vendor',
        priority_uom          => 'PriorityUnit',
        cost_uom              => 'CostUnit',
        documentation_url     => 'Documentation',
        created               => 'Created',
        );

    $entry->specification(1);

    _set_values($entry, $args, \%columns);

    return;
    }

sub _import_redefhead {
    my ($entry, $args, $parent) = @_;

    my %columns = (
        version               => 'Version',
        author                => 'Author',
        codepage              => 'Codepage',
        country_geo           => 'Countrykey',
        publication_status    => 'PublicationStatus',
        );

    #-- element: Responsibles

    _set_values($entry, $args, \%columns,$parent);

    return;
    }

sub _import_participants {
    my ($entry, $args) = @_;

    debug('Importing participants');

    foreach my $part_proto(@{$args}) {
        my $pid = delete $part_proto->{Id};
        my $participant = 
          $entry->result_source->schema->resultset('Participant')->create({
            participant_uid   => $pid,
            participant_name  => delete $part_proto->{Name} || $pid,
            description       => delete $part_proto->{Description},
            participant_type  => $part_proto->{ParticipantType}->{Type},
            parent_node       => $entry->id,            
            participant_scope => ref($entry) =~ /Package/
                 ? 'Package' : 'Process',
            });
        delete $part_proto->{ParticipantType};
        $participant->update({ attributes => $part_proto }) 
            if (keys %{$part_proto});
        }

    return;
    }

sub _import_applications {
    my ($entry, $args) = @_;
    
    debug('Importing applications');
    
    foreach my $app_proto(@{$args}) {
        my $app = _import_application($entry, $app_proto);
        $app->update();
        die("Double-def app") if($APPMAP{$app->application_uid});
        $APPMAP{$app->application_uid} = $app;
        }

    return;
    }

sub _import_application {
    my ($entry, $args) = @_;

    my $app = $entry->result_source->schema->resultset('Application')->create({
        application_uid   => $args->{Id},
        application_name  => $args->{Name} || $args->{Id},
        parent_node       => $entry->id,
        description       => $args->{Description},
        application_scope => ref($entry) =~ /Package/ ? 'Package' : 'Process',
        });

    _set_elements($app, $args);

    return $app;
    }

sub _import_processes {
    my ($entry, $args) = @_;
    
    debug('Importing processes');
    
    foreach my $process(@{$args}) {
        _import_process($entry, $process);
        }

    return;
    }

sub _import_process {
    my ($entry, $args) = @_;
    
    my $process = $entry->add_to_processes({
        process_uid  => $args->{Id},
        });
    $process->process_name($args->{Name}) if $args->{Name};

    #-- element: ProcessHeader
    my %columns = (
        description => 'Description',
        created     => 'Created',
        priority    => 'Priority',
        valid_from  => 'ValidFrom',
        valid_to    => 'ValidTo',
        );
    _set_values($process, $args->{ProcessHeader}, \%columns);

    #-- element: RedefinableHeader
    _import_redefhead($process, $args->{RedefinableHeader}, $entry);

    #-- elements: data fields
    _set_elements($process, $args);

    #-- element: Participants
    _import_participants($process, $args->{Participants}->{Participant}) 
        if $args->{Participants};

    #-- element: Applications
    _import_applications($process, $args->{Applications}->{Application}) 
        if $args->{Applications};

    #-- element: ActivitySets

    #-- element: Activities
    debug('Importing activities');
    my $i = 0;
    my $transition_map = {};
    my $deadline_map = {};
    if($args->{Activities} && $args->{Activities}->{Activity}) {
        foreach my $act_proto(@{ $args->{Activities}->{Activity} }) {
            my $activity = _import_activity(
                $process, $act_proto, $transition_map, $deadline_map
                );
            $activity->update();
            $i++;
            }
        }

    #-- element: Transitions
    debug('Importing transitions');    
    if($args->{Transitions} && $args->{Transitions}->{Transition}) {
        foreach my $trans_proto(@{ $args->{Transitions}->{Transition} }) {
            my $transition = _import_transition(
                $process, $trans_proto, $transition_map, $deadline_map
                );
            $transition->update();
            }
        }

    die("Not all transitionrefs have matching transitions") 
        if(scalar keys %{$transition_map});
    die("Not all deadlines have matching transition conditions") 
        if(scalar keys %{$deadline_map});
    
    #my $start_activities = $process->start_activities;
    #warn("Too many start activities")
    #    if(scalar @{$start_activities} > 1);
    
    $process->mark_back_edges();    
    
    $process->update();

    return;
    }

sub _import_activity {
    my ($process, $args, $trans_map, $deadline_map) = @_;
    
    debug('Importing activity');

    #-- attributes
    my $activity = $process->add_to_activities({
        activity_uid     => $args->{Id},
        activity_name    => $args->{Name} || $args->{Id},
        activity_type    => $args->{Route} ? 'Route' : (
            $args->{BlockActivity} ? 'BlockActivity' : (
            $args->{Event} ? 'Event' : 'Implementation')
            ),
        });

    #-- elements: Description, Priority, Icon, Documentation
    my %columns = (
        description         => 'Description',
        priority            => 'Priority',
        documentation_url   => 'Documentation',
        icon_url            => 'Icon',
        start_mode          => 'StartMode',
        finish_mode         => 'FinishMode',
        start_quantity      => 'StartQuantity',
        completion_quantity => 'CompletionQuantity',
        );
    _set_values($activity, $args, \%columns);

    _set_elements($activity, $args);

    #-- element: StartMode + FinishMode
    $activity->start_mode('Manual') if($args->{StartMode} && 
        ( ref($args->{StartMode}) ? 
            $args->{StartMode}->{Manual} : ($args->{StartMode} eq 'Manual'))
        );
    $activity->finish_mode('Manual') if($args->{FinishMode} &&
        ( ref($args->{FinishMode}) ? 
            $args->{FinishMode}->{Manual} : ($args->{FinishMode} eq 'Manual'))
        );
    
    #-- element: Deadline
    if($args->{Deadline}) {
        my @deadlines = @{ $args->{Deadline}->{Deadline} };
        foreach my $dead(@deadlines) {
            die("Illegal deadline") 
                if ($deadline_map->{$dead->{'ExceptionName'}});
            $deadline_map->{$dead->{'ExceptionName'}} = {
                activity_id  => $activity->id,
                duration     => $dead->{'DeadlineDuration'},
                execution    => $dead->{'Execution'},
                };
            }
        }

    #-- element: TransitionRestrictions
    # split_type => 'SplitType',
    # join_type  => 'JoinType',
    if($args->{TransitionRestrictions} && 
       $args->{TransitionRestrictions}->{TransitionRestriction}) {
        my @restrict = @{$args->{TransitionRestrictions}->{TransitionRestriction}};
        my $seen_split = 0;
        my $seen_join  = 0;        
        foreach my $r(@restrict) {
            my @rkeys = keys %{$r};
            die("Invalid TransitionRestriction") 
                unless(scalar(@rkeys) == 1 || scalar(@rkeys) == 2);
            foreach my $rtype(@rkeys) {
                if($rtype eq 'Split') {
                    $activity->split_type($r->{$rtype}->{Type});
                    die("Invalid TransitionRestriction: multiple splits") 
                        if $seen_split++;
                    }
                elsif($rtype eq 'Join') {
                    $activity->join_type($r->{$rtype}->{Type});
                    die("Invalid TransitionRestriction: multiple joins") 
                        if $seen_join++;
                    }
                else {
                    die("Invalid TransitionRestriction");
                    }

                # from_split/to_join position starts at 1
                my $pos = 1;
                foreach my $trans(@{ $r->{$rtype}->{TransitionRefs}->{TransitionRef} }) {
                    $trans_map->{$trans->{Id}}->{$rtype} ||= [];
                    push(@{ $trans_map->{$trans->{Id}}->{$rtype} }, 
                        [$activity->id, $pos++]);
                    }
                }
            }
        }

    #-- element: Performer
    if($args->{Performers}) {
        my @performers = ref($args->{Performers}->{Performer}) ? 
                         @{$args->{Performers}->{Performer}} : 
                         ($args->{Performers}->{Performer});
        _import_performers($process, $activity, @performers);
        }

    #-- element: Implementation Route BlockActivity Event
    if($activity->is_implementation_type) {
        #-- implementation_type: No Tool Task SubFlow Reference
        my $impl = $args->{Implementation} || { 'No' => undef };
        my @itypes = keys %{$impl};
        die("Invalid Implementation specification") if(scalar(@itypes) > 1);
        my $impl_type = $itypes[0] || 'No';
        $activity->implementation_type($impl_type);
        if($activity->is_impl_task) {
            my ($type, @tasks) = ();
            if($impl_type eq 'Tool') {
                @tasks = @{$impl->{Tool}};
                $type = 'Tool';
                foreach my $task(@tasks) {
                    _add_task($activity, $task, $type);
                    }
                }
            elsif($impl_type eq 'Task') {
                my @tkeys = keys %{$impl->{Task}};
                if(scalar @tkeys > 1) {
                    die("Too many tasks (Task element takes no attributes)");
                    }
                
                $type = $tkeys[0];
                if($type) {
                    my $task = $impl->{Task}->{$type};
                    $type =~ s/^Task//;
                    _prepare_task($type, $task);
                    _add_task($activity, $task, $type);
                    }
                }
            }
        elsif(!$activity->is_impl_no && !$activity->is_impl_subflow 
            && !$activity->is_impl_reference) {
            #die("Invalid Activity implementation");
            }
        }
    elsif(!$activity->is_route_type && !$activity->is_block_type 
       && !$activity->is_event_type) {
        die("Invalid Activity implementation");
        }

    #-- element: Limit

    return $activity;
    }

sub _prepare_task {
    my ($type, $task) = @_;    

    debug('Preparing task');

    $task->{Script} = $task->{Script}->textContent 
        if(ref($task->{Script}) eq 'XML::LibXML::Element');

    # TaskApplication values for XML::LibXML::Element elements
    if ($type eq 'Application') {
        my $actual_params = delete $task->{ActualParameters}->{ActualParameter};
        if($actual_params) {
            $task->{ActualParameters}->{ActualParameter} = 
                _mapxml($actual_params);
            }
        else {
            delete $task->{ActualParameters};
            }
        
        # normalize Actual and TestValue XML::LibXML::Element elements
        my $maps = $task->{DataMappings}->{DataMapping};
        if($maps) {
            foreach(@{$maps}) {
                $_->{TestValue} = _checkxml($_->{TestValue});
                $_->{Actual}    = _checkxml($_->{Actual});
                }
            }
        else {
            delete $task->{DataMappings};
            }
        }
    
    # normalize ActualParameter values
    my %msgtypes = ( 
        Message    => 'send|receive', 
        MessageIn  => 'user|service', 
        MessageOut => 'user|service'
        );
    
    foreach my $msgtype(keys %msgtypes) {
        my $re = $msgtypes{$msgtype};
        if($type =~ /$re/i) {
            my $msg = $task->{$msgtype};
            
            my $params = $msg->{ActualParameters}->{ActualParameter};            
            if($params) {
                $msg->{ActualParameters}->{ActualParameter} = _mapxml($params);
                }
            else {
                delete $msg->{ActualParameters};
                }
            
            my $dmap = $msg->{DataMappings}->{DataMapping};
            if($dmap) {
                foreach ( @{ $msg->{DataMappings}->{DataMapping} } ) {
                    $_->{TestValue} = _checkxml($_->{TestValue});
                    $_->{Actual}    = _checkxml($_->{Actual});
                    }                
                }
            else {
                delete $msg->{DataMappings};
                }
            }
        elsif ($task->{$msgtype}) {
            delete $task->{$msgtype};
            }
        }
    }

sub _add_task {
    my ($activity, $task, $type) = @_;

    debug('Adding task');

    my $task_tool = $activity->add_to_tasks({
        task_uid    => $task->{Id},
        task_name   => delete $task->{Name} || $activity->activity_name,
        description => delete $task->{Description} || $activity->description,
        task_type   => $type,
        }) or die("Invalid Task");
    
    if ($type eq 'Tool' || $type eq 'Application') {
        my $app = $APPMAP{ $task->{Id} } 
            or die("No application for task $task->{Id}");
        $task_tool->application_id($app->id);
        if($task->{ActualParameters}->{ActualParameter}) {
            my $params = delete $task->{ActualParameters}->{ActualParameter};
            $task_tool->actual_params($params);
            }
        }
    elsif ($type eq 'User' || $type eq 'Manual') {
        if($task->{Performers}) {
            my @performers = ref($task->{Performers}->{Performer}) ?
                             @{$task->{Performers}->{Performer}} :
                             ($task->{Performers}->{Performer});
            _import_performers($activity->process, $task_tool, @performers);
            }        
        }
    
    _set_elements($task_tool, $task);
    delete $task->{Id};
    
    debug('Setting taskdata');
    delete $task->{WebServiceFaultCatch};
    delete $task->{ActualParameters};
    delete $task->{Performers};
    $task_tool->task_data($task) if(keys %{$task});
    $task_tool->update();
    }

sub _import_performers {
    my ($process, $container, @performers) = @_;

    debug('Importing performers');

    foreach my $performer(@performers) {
        die("Invalid Performer '$performer' (Missing element data)") 
            unless $performer;
        my $participant = 
            $process->participants->find({ participant_uid => $performer }) 
            or die("Invalid Performer '$performer' (Participant unknown)");
        $container->add_to_performers({
            participant_id   => $participant->id,
            container_id     => $container->id,
            performer_scope  => ref($container) =~ /Task/ ? 'Task' : 'Activity',
            }) or die("Performer '$performer' not created");
        }
    }

sub _import_transition {
    my ($process, $args, $trans_map, $deadline_map) = @_;
    
    debug('Importing transition');

    my $act_out = join( '_', split( /\s+/, $args->{From} ) );
    my $act_in  = join( '_', split( /\s+/, $args->{To} ) );
    my $from    = $process->activities->search({activity_uid => $act_out})->next
                  or die("Unknown activity $args->{From}");
    my $to      = $process->activities->search({activity_uid => $act_in })->next 
                  or die("Unknown activity $args->{To}");

    my $transition = $process->add_to_transitions({
        transition_uid   => $args->{Id},
        transition_name  => $args->{Name},
        from_activity_id => $from->id,
        to_activity_id   => $to->id,
        });

    if($args->{Description}) {
        $transition->description($args->{Description});
        }
    if($args->{Quantity}) {
        $transition->quantity($args->{Quantity});
        }
    if($args->{Condition}) {
        my $condition = $args->{Condition};
        if(ref($condition) eq 'XML::LibXML::Element') {
            if(my $ctype = $condition->getAttributeNode('Type')) {
                $transition->condition_type($ctype->nodeValue);
                }
            else {
                $transition->condition_type('NONE');
                }
            
            my @exprs = $condition->getChildrenByTagName('Expression');
            my $expr = $exprs[0] || $condition;            
            if(my $line = _trim($expr->textContent)) {
                $transition->condition_expr($line);
                }
            }
        else {
            $transition->condition_type($args->{Condition}->{Type} || 'NONE');
            $transition->condition_expr($condition->{content});
            }
        
        my $ctype = $transition->condition_type || die("No condition type");
        if($ctype eq 'EXCEPTION') {
            if(my $dead = delete $deadline_map->{$transition->condition_expr}) {
                $transition->create_related(deadline => $dead)
                    or die("Could not create deadline");
                }
            }

        }

    # transition references
    if($args->{Id} && $trans_map->{ $args->{Id} }) {
        my $tref = delete $trans_map->{$args->{Id}};
        foreach my $type(grep { $tref->{$_} } qw/Split Join/) {
            my $rel = $type eq 'Split' ? 'from_split' : 'to_join';
            foreach my $activity_set(@{ $tref->{$type} }) {
                #XXX relation severed
                #$transition->create_related($rel, {
                $transition->create_related(transition_refs => {
                    activity_id   => $activity_set->[0],
                    position      => $activity_set->[1],
                    split_or_join => uc($type),
                    });
                }
            }
        }

    return $transition;
    }

sub _set_values {
    my ($entry,$args,$cols,$parent) = @_;

    debug('Setting values');

    my %columns = %{$cols};
    foreach my $method(keys %columns) {
        my $value = $args->{ $columns{$method} };
        next if(ref($value));
        $value ||= $parent->$method if $parent;
        $entry->$method($value) if $value;
        }

    return;
    }

sub _trim {
	my $content = shift;
	return unless defined $content;
    $content =~ s/(^\s*|\s*$)//g;
    return $content;
    }

#-- elements:
# DataFields, ExtendedAttributes, FormalParameters, ActualParameters,
# DataMappings, Assignments
sub _set_elements {
    my ($entry, $args) = @_;

    debug('Importing elements');

    my $a = { actual_params => [ 'ActualParameters', 'ActualParameter' ] };
    my $f = { formal_params => [ 'FormalParameters', 'FormalParameter' ] };
    my $d = { data_fields   => [ 'DataFields', 'DataField' ] };
    my $s = { assignments   => [ 'Assignments', 'Assignment' ] };
    
    my $i = { input_sets    => [ 'InputSets',  'InputSet'  ] };
    my $o = { output_sets   => [ 'OutputSets', 'OutputSet' ] };
    my $r = { artifacts     => [ 'Artifacts',  'Artifact'  ] };    

    my $m = { data_maps     => [ 'DataMappings', 'DataMapping' ] };
    my $e = { extended_attr => [ 'ExtendedAttributes', 'ExtendedAttribute' ] };
    my $v = { event_attr    => [ 'Event' ] };    
    my %types = (
        Package      => [$e, $d, $r],
        Application  => [$f, $e],
        Process      => [$f, $e, $d, $s],
        Activity     => [$e, $d, $s, $v, $i, $o],
        ActivityTask => [$a, $m, $e],
        Transition   => [$s],
        #Message(In|Out) => [],
        );
    my @pack = grep { ref($entry) =~ /^BPM::Engine::Store::Result::($_)$/ } 
               keys %types;
    die("Invalid regexp $entry ") unless scalar @pack == 1;
    my $container = $pack[0];
    
    foreach my $type(@{ $types{$container} }) {
        my $field = (keys %{$type})[0];
        my ($multi, $single) = @{ $type->{$field} };
        my $json = '';
        #warn "Storing field $field multi $multi single $single type $type container $container entry $entry" 
            #if $container eq 'Package';
        if(!$single && $multi eq 'Event') {
            $json = delete $args->{$multi};
            my @event_types = keys %{$json};
            next unless scalar @event_types;
            $json = scalar @event_types ? $json->{$event_types[0]} : {};
            
            my $ev = $event_types[0] || 'EndEvent';
            $ev =~ s/Event$//;
            $entry->event_type($ev);
            }
        elsif($args->{$multi} && $args->{$multi}->{$single}) {
            $json = delete $args->{$multi}->{$single};
            delete $args->{$multi};
            next unless $json->[0];
            # get rid of XML::LibXML::Element objects from mixed-schema elements
            if($multi eq 'ExtendedAttributes' && ref($json->[0]) eq 'XML::LibXML::Element') {
                $json = [map { 
                          { Name => $_->getAttribute('Name') , 
                            Value => $_->getAttribute('Value') } 
                        } @$json];
                }
            elsif($container eq 'ActivityTask' && $multi eq 'ActualParameters') {
                $json = _mapxml($json);
                }
            elsif($multi =~ /^(Artifacts|DataFields|DataMappings|Assignments|FormalParameters)$/) {
                foreach(@{$json}) {
                    delete $_->{'NodeGraphicsInfos'};
                    _hashxml($_);
                    }
                }
            }
        else {
            next;
            }
        eval {
            $entry->$field($json);
            };
        if($@) {
#use Data::Dumper;
#warn Dumper $json;            
            die "Error setting $field ($multi) as JSON: $@";
            }
        }

    }

sub _hashxml {
    my $hash = shift;
    return unless(ref($hash) eq 'HASH');
    
    foreach my $key(keys %{$hash}) {
        $hash->{$key} = _serialize_schema($hash->{$key}) 
            if($key eq 'DataType' && $hash->{$key}->{SchemaType});
        $hash->{$key} = _checkxml($hash->{$key});
        delete $hash->{$key} unless(defined $hash->{$key});
        }
    }

sub _mapxml {
    my $val = shift;
    return [ grep { $_ } map { _checkxml($_) } @{$val} ];
    }

sub _checkxml {
    my $val = shift;
    return unless $val;

    if(blessed($val)) {
        #warn "Inspecting " . $val->nodeName . ' withChildren ' . $val->hasChildNodes();
        unless(ref($val) eq 'XML::LibXML::Element') {
            die("Invalid node type, not an XML::LibXML::Element");
            }
        return unless $val->hasChildNodes();
        return { 
            content => $val->firstChild->textContent,
            map { $_->nodeName => $_->value } $val->attributes()
            };
        }
    elsif(ref($val) eq 'HASH' && defined $val->{content}) {
        return $val->{content};
        }
    else {
        return $val;
        }
    }

sub _serialize_schema {
    my $val = shift;
    return unless $val;
    
    my $el = $val->{SchemaType}->{schema}->[0] or return;
    die("Schema is not an 'XML::LibXML::Element'") 
        unless ref($el) eq 'XML::LibXML::Element';
    $val->{SchemaType} = $el->toString;
    
    return $val;
    }

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
__END__

=pod

=head1 NAME

BPM::Engine::Store::ResultSet::Package - Package DBIC resultset

=head1 VERSION

0.01

=head1 SYNOPSIS

    my $rs = $schema->resultset('Package');
    my $package = $rs->create_from_xpdl('/path/to/workflows.xpdl');

=head1 DESCRIPTION

This module extends L<DBIx::Class::ResultSet|DBIx::Class::ResultSet> for the 
C<Package> table.

=head1 METHODS

=head2 create_from_xpdl

    my $package = $rs->create_from_xpdl($input);

Takes xml input and returns a newly created Package row. Input can be a file, 
URL, string or io stream; see C<xpdl_hash()> in 
L<BPM::Engine::Util::XPDL|BPM::Engine::Util::XPDL> for details.

=head1 EXCEPTIONS

If the XML is found to be inconsistent, C<create_from_xpdl()> just dies with an 
error message and nothing is inserted in the database.

=head1 SEE ALSO

=over 4

=item L<BPM::Engine::Store::Result::Package|BPM::Engine::Store::Result::Package>

=back

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
