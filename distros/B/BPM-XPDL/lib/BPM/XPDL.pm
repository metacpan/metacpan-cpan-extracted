# Copyrights 2009-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package BPM::XPDL;
use vars '$VERSION';
$VERSION = '0.93';

use base 'XML::Compile::Cache';

use XML::Compile::Util qw/type_of_node unpack_type pack_type/;
use Log::Report 'business-xpdl', syntax => 'SHORT';
use BPM::XPDL::Util;


# map namespace always to the newest implementation of the protocol
my %ns2version =
 ( &NS_XPDL_009 => '0.09'
 , &NS_XPDL_10  => '1.0'
 , &NS_XPDL_20  => '2.0'
 , &NS_XPDL_21  => '2.1'
 , &NS_XPDL_22  => '2.2'
 );

my %info =
 ( '0.01' => { }  # not usable
 , '0.09' =>
     { prefixes => { '' => NS_XPDL_009 }
     }
 , '1.0' =>
     { prefixes => { '' => NS_XPDL_10 }
     }
 , '2.0alpha-21' =>
     { prefixes => { '' => NS_XPDL_20 }
     }
 , '2.0alpha-24' =>
     { prefixes => { '' => NS_XPDL_20 }
     }
 , '2.0'         =>   # alpha namespace used for final product
     { prefixes => { '' => NS_XPDL_20 }
     }
 , '2.1' =>
     { prefixes => { '' => NS_XPDL_21 }
     }
 , '2.2' =>
     { prefixes => { '' => NS_XPDL_22 }
     }
 );

#--------


sub new($)
{   my $class = shift;
    $class->SUPER::new(direction => 'RW', @_);
}

sub init($)
{   my ($self, $args) = @_;
    $args->{allow_undeclared} = 1
        unless exists $args->{allow_undeclared};

    $self->SUPER::init($args);

    $self->anyElement('ATTEMPT');
    $self->addCompileOptions(RW => sloppy_floats => 1, sloppy_integers => 1);
    $self->addCompileOptions(READERS => mixed_elements => 'XML_NODE');

    my $version = $args->{version}
        or error __x"XPDL object requires an explicit version";

    unless(exists $info{$version})
    {   exists $ns2version{$version}
            or error __x"XPDL version {v} not recognized", v => $version;
        $version = $ns2version{$version};
    }
    $self->{version} = $version;
    my $info = $info{$version};
    $self->{namespace} = $info->{prefixes}{''};

    my $prefix_keys = $self->{prefixed} = delete $args->{prefix_keys};

    $self->addPrefixes($info->{prefixes});
    $self->addKeyRewrite('PREFIXES(xpdl)') if $prefix_keys;

    (my $xsd = __FILE__) =~ s!\.pm!/xsd!;
    my @xsds = glob "$xsd/xpdl-$version/*";

    # support deprecated versions
    if($version gt '1.0')   # $version is a version label, not number
    {   trace "loading deprecated xpdl 1.0";
        $self->addPrefixes(xpdl10 => NS_XPDL_10);
        push @xsds, glob "$xsd/xpdl-1.0/*";
        $self->addKeyRewrite('PREFIXES(xpdl10)') if $prefix_keys;

        # this trick is needed because the StartMode element became an
        # attribute in the same structure
        $self->addKeyRewrite(
          { pack_type(NS_XPDL_10, 'StartMode' ) => 'dep_StartMode'
          , pack_type(NS_XPDL_10, 'FinishMode') => 'dep_FinishMode'} );
    }

    if($version ge '2.1')
    {   trace "loading deprecated xpdl 2.0";
        $self->addPrefixes(xpdl20 => NS_XPDL_20);
        push @xsds, glob "$xsd/xpdl-2.0/*";
        $self->addKeyRewrite('PREFIXES(xpdl20)') if $prefix_keys;
    }

    $self->importDefinitions(\@xsds);
    $self;
}


sub from($@)
{   my ($thing, $source, %args) = @_;

    my $xml  = XML::Compile->dataToXML($source);
    my $top  = type_of_node $xml;
    my ($ns, $topname) = unpack_type $top;
    my $version = $ns2version{$ns}
       or error __x"unknown XPDL version with namespace {ns}", ns => $ns;

    $topname eq 'Package'
       or error __x"file does not contain a Package but {local}"
             , local => $topname;

    my ($self, $convert);
    if(ref $thing)
    {   # instance method
        $self    = $thing;

        ! $self->{prefixed}
           or error __x"cannot use prefixed_keys with version conversion";

        $convert = 1;
    }
    else
    {   # class method: can determine version myself
        $self    = $thing->new(version => $version, %args);
        $convert = 0;
    }

    my $r    = $self->reader($top, %args)
        or error __x"root node `{top}' not recognized", top => $top;

    my $data =  $r->($xml);

    if($convert)
    {   # upgrade structures.  Even when the versions match, they may
        # contain deprecated structures which can be removed.
        $self->convert10to20($data)
            if $self->version gt '1.0';

        $self->convert20to21($data)
            if $self->version gt '2.0';
    }

    (pack_type($self->namespace, 'Package'), , $data);
}

sub convert10to20($)
{   my ($self, $data) = @_;

    trace "Convert xpdl version from 1.0 to 2.0";

    # The conversions to be made are described in the XPDL specification
    # documents.  However, be aware that there are considerable additions.

    my $ns = $self->namespace;
    my $prefix
      = $ns eq NS_XPDL_20 ? 'xpdl20'
      : $ns eq NS_XPDL_21 ? 'xpdl21'
      : panic;

    # do not walk more than one HASH level at a time, to avoid creation
    # of unused HASHes.
    my $wfps = $data->{WorkflowProcesses} || {};
    foreach my $wfp (@{$wfps->{WorkflowProcess} || []})
    {
        my $acts = $wfp->{Activities} || {};
        foreach my $act (@{$acts->{Activity} || []})
        {   # Start/Finish mode from element -> attribute
            if(my $sm = delete $act->{dep_StartMode})
            {   (my $mode, undef) = %$sm; # only 1 key-value pair!
                $act->{StartMode} = $mode;
            }
            if(my $fm = delete $act->{dep_FinishMode})
            {   (my $mode, undef) = %$fm;
                $act->{dep_FinishMode} = $mode;
            }

            # BlockId -> ActivitySetId
            if(my $ba = $act->{BlockActivity})
            {   # rename option BlockId into ActivitySetId
                $ba->{ActivitySetId} = delete $ba->{BlockId}
                    if $ba->{BlockId};
            }

            # DeadlineCondition -> DeadlineDuration
            foreach my $dead (@{$act->{Deadline} || []})
            {  $dead->{DeadlineDuration} = delete $dead->{DeadlineCondition}
                   if $dead->{DeadlineCondition};
            }

            # Remove Tool attribute "Type"
            if(my $impl =  $act->{Implementation})
            {   if(my $tools = $impl->{Tool})
                {   delete $_->{Type} for @$tools;
                }
            }
        }

        # remove Index attribute to FormalParameter
        my $fps = $wfp->{FormalParameters} || {};
        foreach my $param (@{$fps->{FormalParameter} || []})
        {   delete $param->{Index};
        }

        my $appls = $wfp->{Applications} || {};
        foreach my $appl (@{$appls->{Application} || []})
        {   my $afps = $appl->{FormalParameters} || {};
            for my $param (@{$afps->{FormalParameter}||[]})
            {   delete $param->{Index};
            }
        }
  
        # Condition/Xpression to Condition/Expression
        my $trs = $wfp->{Transitions} || {};
        for my $trans (@{$trs->{Transition} || []})
        {   my $cond = $trans->{Condition} or next;
            foreach ($cond->getChildrenByLocalName('Xpression'))
            {   $_->setNodeName('Expression');
                $_->setNamespace($ns, $prefix, 1);
            }
        }

        my $sets = $wfp->{ActivitySets} || {};
        foreach my $set (@{$sets->{ActivitySet} || []})
        {   my $strans = $set->{Transitions} || {};
            foreach my $trans (@{$strans->{Transition} || []})
            {   my $cond = $trans->{Condition} or next;
                foreach ($cond->getChildrenByLocalName('Xpression'))
                {   $_->setNodeName('Expression');
                    $_->setNamespace($ns, $prefix, 1);
                }
            }
        }

        # Order in WorkflowProcess changed.  This is a no-op for X::C
    }

    $data->{PackageHeader}{XPDLVersion} = '2.0';
    $data;
}

sub convert20to21($)
{   my ($self, $data) = @_;

    trace "Convert xpdl version from 2.0 to 2.1";

    # Tool has been removed from the spec.  However, it can still be
    # used in the old namespace, and I do not know how to convert it
    # to 2.1 structures (yet)

    my $ns = $self->namespace;
    my $prefix
      = $ns eq NS_XPDL_21 ? 'xpdl21'
      : panic;


    # do not walk more than one HASH level at a time, to avoid creation
    # of unused HASHes.
    my $wfps = $data->{WorkflowProcesses} || {};
    foreach my $wfp (@{$wfps->{WorkflowProcess} || []})
    {
        my $acts = $wfp->{Activities} || {};
        foreach my $act (@{$acts->{Activity} || []})
        {   # Rewrite Tool to Task/TaskApplication
            if(my $impl = $act->{Implementation})
            {   foreach my $tool (@{delete $impl->{Tool} || []})
                {  my %task = %$tool;
                   delete $task{PackageRef};         # ?relocate info?
                   delete $task{ExtendedAttributes}; # ?into DataMapping?
                   delete $task{Type};   # shouldn't be there, rem in 2.0
                   $impl->{Task}{TaskApplication} = \%task;
                }
            }
        }

        # Condition/Xpression to Condition/Expression
        my $trs = $wfp->{Transitions} || {};
        for my $trans (@{$trs->{Transition} || []})
        {   my $cond = $trans->{Condition} or next;
            foreach ($cond->getChildrenByLocalName('Expression'))
            {   $_->setNamespace($ns, $prefix, 1);
            }
        }

        my $sets = $wfp->{ActivitySets} || {};
        foreach my $set (@{$sets->{ActivitySet} || []})
        {   my $strans = $set->{Transitions} || {};
            foreach my $trans (@{$strans->{Transition} || []})
            {   my $cond = $trans->{Condition} or next;
                foreach ($cond->getChildrenByLocalName('Expression'))
                {   $_->setNamespace($ns, $prefix, 1);
                }
            }
        }
    }

    $data->{PackageHeader}{XPDLVersion} = '2.1';
    $data;
}

#----------


sub version()   {shift->{version}}
sub namespace() {shift->{namespace}}

#--------

sub create($)
{   my ($self, $data) = @_;
    my $doc  = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $wr   = $self->writer('Package')
        or panic "cannot find Package type";

    my $root = $wr->($doc, $data);
    $doc->setDocumentElement($root);
    $doc;
}

1;
