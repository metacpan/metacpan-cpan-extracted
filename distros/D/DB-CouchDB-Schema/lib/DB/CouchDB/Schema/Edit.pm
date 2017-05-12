package DB::CouchDB::Schema::Edit;
use DB::CouchDB::Schema;
use Moose;
use Term::ReadLine;
use File::Temp qw/tempfile tempdir/;
use Pod::Usage;

has schema => (is => 'rw', isa => 'DB::CouchDB::Schema');
has term   => (is => 'ro', default => sub {
        return Term::ReadLine->new('CouchDB::Schema Editor');
    }
);
has commands => (is => 'rw', isa => 'HashRef');
has view => (is => 'rw', isa => 'Str');
has func => (is => 'rw', isa => 'Str');

sub BUILD {
    my $self = shift;
    my %commands = (
        'Select Design Doc' => { ord => 1, 
            run => sub {
                $self->select_design();
            }
        },
        'Select View Func' => {ord => 2,
            run => sub {
                $self->select_view_func();
            }
        },
        'Edit View Func' => {ord => 3,
            run => sub {
                $self->edit_view_func();
            }
        },
        'Quit' => { ord => 100, 
            run => sub {
                $self->quit();
            }
        }
    );
    $self->commands(\%commands);
}

sub reset {
    my $self = shift;
    $self->{view} = undef;
    $self->{func} = undef;
};

sub select_design {
    my $self = shift;
    $self->{func} = undef;
    my @views; 
    my $designnames = $self->schema()->get_views();
    while (my $designname = $designnames->next_key()) {
        my $viewdoc = $self->schema()->get($designname);
        push @views, $designname;
    }
    my $view = $self->_select_from_list("Select a design doc:", @views);
    $self->view($view);
    $self->select_view_func();
}

sub select_view_func {
    my $self = shift;
    if ($self->view()) {
        my @funcs;
        my $designdoc = $self->schema()->get($self->view());
        for my $fname (keys %{$designdoc->{views}}) {
            push @funcs, $fname;
        }
        my $funcname = $self->_select_from_list(
            "Select a view function" => @funcs
        );
        $self->func($funcname);
        $self->edit_view_func();
    } else {
        print STDERR "You have to select a Design Doc first",$/;
    }
}

sub edit_view_func {
    my $self = shift;
    my $viewobj = $self->schema->get($self->view());
    my $viewfunc = $viewobj->{views}->{$self->func};
    my $map; 
    my $reduce;
    $map = $viewfunc->{map} if $viewfunc->{map}; 
    $reduce = $viewfunc->{reduce} if $viewfunc->{reduce};
    my $sel = $self->_select_from_list('Select:', 'map', 'reduce');
    my ($fh, $name) = tempfile('tmpXXXXXXXXXX', SUFFIX => '.js');
    my $editor = $ENV{EDITOR} || 'vim';
    LOOP: while (1) {
        if ($sel eq 'map') {
            print $fh $map;
            close $fh;
            system("$editor $name");
            open $fh, $name;
            {
                local $/;
                $viewfunc->{map} = <$fh>;
            }
            unlink($name);
        } else {
            print $fh $reduce;
            close $fh;
            system("$editor $name");
            open $fh, $name;
            {
                local $/;
                $viewfunc->{reduce} = <$fh>;
            }
            unlink($name);
        }
        if (defined $viewfunc->{reduce} && 
            $viewfunc->{reduce} eq '' ||
                not defined $viewfunc->{reduce}) {
            delete $$viewfunc{reduce};
        }
        if ($self->test_view($viewfunc)) {
            $self->save_view($viewobj);
            last LOOP;
        } else {
            my $continue;
            $self->get_response('Stop Editing this view?[Y/n]: ', sub {
                my $response = shift;
                $continue = 1 if (lc $response eq 'n');
                return 1;
            });
            redo LOOP if $continue;
            last LOOP;
        }
    }
}

sub save_view {
    my $self = shift;
    my $viewobj = shift;
    my $result = $self->schema()->server->update_doc(
        $viewobj->{_id} => $viewobj
    ); 
}

sub test_view {
    my $self = shift;
    my $viewfunc = shift;
    my $save;
    my $server = $self->schema()->server();  
    my $test = $server->temp_view($viewfunc);
    if ($test->err) {
        warn $test->errstr(), $/;
        return;
    }
    VIEW: while (my $doc = $test->next()) {
        print $server->json->encode($doc);
        my $stop;
        $self->get_response('Continue viewing results?[Y/n]', sub {
            my $response = shift;
            $stop = 1 if (lc $response eq 'n');
            return 1;
        });
        last VIEW if ($stop); 
    }
    
    $self->get_response('Save this view?[y/N]: ', sub {
        my $response = shift;
        $save = 1 if (lc $response eq 'y');
        return 1;
    });
    return $save;
}

sub _select_from_list {
    my $self = shift;
    my $prompt = shift;
    my @list = @_;
    print $prompt, $/;
    my $counter = 0;
    for my $item (@list) {
        print $counter++ . " - " . $item, $/;
    };
    my $selection = shift;
    $self->get_response('Enter a number or name(partials will work): ', sub {
        my $request = shift;
        #print STDERR "the request was $request", $/;
        if ($request =~ /^\d$/) {
            $selection = $list[$request];
            #print STDERR "the selection was $selection", $/;
            return 1 if $selection;
        } else {
            if (my ($item) = grep {$_ =~ /$request/i } @list) {
                $selection = $item;
                $self->term()->addhistory($item);
                #print STDERR "the selection was $selection", $/;
                return 1;
            }
        }
        return;
    });
    return $selection;
};

sub run {
    my $self = shift;
    if (!$self->schema()) {
        $self->connect();
    }
    $self->process_commands();
    $self->quit();
}

sub show_meta {
    my $self = shift;
    print "Editing: ".
        $self->schema()->server()->host() . "/" . 
        $self->schema()->server()->db();
    print $/;
    if ($self->view) {
        print "Selected View: ". $self->view(),$/;
    }
    if ($self->func) {
        print "Selected View Func: ". $self->func(),$/;
    }
    print $/;
}

sub process_commands {
    my $self = shift;
    my $commands = $self->commands();
    my @coms = sort { $commands->{$a}->{ord} <=> $commands->{$b}->{ord} } 
        keys %{$self->commands()};
    while (1) {
        $self->show_meta();
        my $command = $self->_select_from_list("please choose an action:", @coms);
        $self->commands()->{$command}->{run}->();
    }
}

sub connect {
    my $self = shift;
    my $hostname;
    $self->get_response('Enter couchdb host[localhost]: ', sub {
        $hostname = shift;
        if (!$hostname) {
            $hostname = 'localhost';
        }
        return 1;
    }, 1);
    my $port;
    $self->get_response('Enter couchdb port[5984]: ', sub {
        $port = shift;
        $port = '5984' if (!$port);
    });
    my $db;
    my $dblist = DB::CouchDB->new(host => $hostname, port => $port)
        ->all_dbs();
    my $db_name = $self->_select_from_list('Select a Database', @$dblist);
    $self->schema(new DB::CouchDB::Schema->new(host => $hostname,
                                               port => $port,
                                               db   => $db_name
                                              ));
}

sub get_response {
    my $self = shift;
    my $prompt = shift;
    my $validator = shift;
    my $add_history = shift;
    print $/;
    my $response = $self->term()->readline($prompt);
    if (!$validator->($response)) {
        $self->get_response($prompt, $validator);
    } else {
        $self->term()->addhistory($response) if $add_history;
    }
}

sub quit {
    my $self = shift;
    $self->get_response('Quit?[y/N]: ', sub {
        my $quit = shift;
        if (lc($quit) eq 'y') {
            exit 0;
        } else {
            return 1;
        }
    });
}

1;
