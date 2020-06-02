package CLI::Driver::Action;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use CLI::Driver::Class;
use CLI::Driver::Method;
use CLI::Driver::Help;
use Module::Load;
use File::Basename;

with 'CLI::Driver::CommonRole';

###############################
###### PUBLIC ATTRIBUTES ######
###############################

has name          => ( is => 'rw', isa => 'Str' );
has desc          => ( is => 'rw', isa => 'Str' );
has is_deprecated => ( is => 'rw', isa => 'Bool' );
has class         => ( is => 'rw', isa => 'CLI::Driver::Class' );
has 'method'      => ( is => 'rw', isa => 'CLI::Driver::Method' );
has 'help'        => ( is => 'rw', isa => 'CLI::Driver::Help' );

############################
###### PUBLIC METHODS ######
############################

method parse (HashRef :$href!) {

    if ( $href->{is_deprecated} ) {

        my $string = $href->{is_deprecated};
        my $bool   = 0;

        if ( $string =~ /^true$/i or $string == 1 ) {
            $bool = 1;
        }

        $self->is_deprecated($bool);
    }

    if ( $href->{class} ) {

        my $class = CLI::Driver::Class->new;
        my $success = $class->parse( href => $href->{class} );
        if ( !$success ) {
            return 0;
        }

        $self->class($class);
    }
    else {
        return 0;
    }

    if ( $href->{method} ) {

        my $method = CLI::Driver::Method->new;
        my $success = $method->parse( href => $href->{method} );
        if ( !$success ) {
            return 0;
        }

        $self->method($method);
    }
    else {
        return 0;
    }

    if ( $href->{desc} ) {
        $self->desc( $href->{desc} );
    }
    
    my $help = CLI::Driver::Help->new;
    $help->parse( href => $href->{help} );
    $self->help($help);

    return 1;
}

method usage {

    printf "\nusage: %s %s [opts] [-?]\n", basename($0), $self->name;
    printf "description: %s\n", $self->desc if $self->desc;
    print "\n";
    
    my $help = $self->help;

    my @opts;
    push @opts, @{ $self->class->attr };
    push @opts, @{ $self->method->args };

    ##########################################################################

    my %opts;
    foreach my $opt (@opts) {

        if ( $opt->required ) {
            $opts{ $opt->cli_arg } = $opt;
            #  and $opt->is_hard) {
            #     $opts{ $opt->cli_arg } = $opt->method_arg;
            #  }
        }
    }

    # print required
    foreach my $arg ( sort { uc($a) cmp uc($b) } keys %opts ) {
        my $opt = $opts{$arg};
        my $val = $opt->method_arg;
        printf "\t-%s <%s>", $arg, $val;
        print ' (soft)' if $opt->is_soft;
        print ' (multi value)' if $opt->is_array;
        print "\n";
        printf "\t\t%s\n", $help->get_help( $arg ) if $help->get_help( $arg );
    }

    ##########################################################################

    %opts = ();
    foreach my $opt (@opts) {

        if ( $opt->is_optional and !$opt->is_flag ) {
            $opts{ $opt->cli_arg } = $opt;
            #  and $opt->is_hard) {
            #     $opts{ $opt->cli_arg } = $opt->method_arg;
            #  }
        }
    }

    #   print "\n" if keys %opts;

    # print optional
    foreach my $arg ( sort { uc($a) cmp uc($b) } keys %opts ) {
        my $opt = $opts{$arg};
        my $val = $opt->method_arg;
        printf "\t[ -%s <%s> ]", $arg, $val;
        print ' (multi value)' if $opt->is_array;
        print "\n";
        printf "\t\t%s\n", $help->get_help( $arg ) if $help->get_help( $arg );
    }

    ##########################################################################

    %opts = ();
    foreach my $opt (@opts) {

        if ( $opt->is_flag ) {
            $opts{ $opt->cli_arg } = $opt;
            #  and $opt->is_hard) {
            #     $opts{ $opt->cli_arg } = $opt->method_arg;
            #  }
        }
    }

    #   print "\n" if keys %opts;

    # print flags
    foreach my $arg ( sort { uc($a) cmp uc($b) } keys %opts ) {
        my $opt = $opts{$arg};
        printf "\t[ --%s ]\n", $arg;
        printf "\t\t%s\n", $help->get_help( $arg ) if $help->get_help( $arg );
    }

    ##########################################################################
    # print examples
    if( $help->has_examples ){
        
        my $cmd = sprintf "%s %s", basename($0), $self->name;
        
        print "\n";
        print "Examples:\n";
        foreach my $eg ( @{$help->examples} ){
            printf "\t%s %s\n", $cmd, $eg;
        }
    }
    
    #########################################################################

    print "\n";
    exit;
}

method _new_class {

    my $class      = $self->class;
    my $class_name = $class->name;
    my %attr       = $class->get_signature;

    load $class_name;
    my $obj = $class_name->new(%attr);

    my @soft_req = $class->find_req_attrs( hard => 0, soft => 1 );

    foreach my $opt (@soft_req) {

        my $attr = $opt->method_arg;

        if ( !defined $obj->$attr ) {
            confess "failed to determine $attr";
        }
    }
    
    return $obj;
}

method do {

    my $obj = $self->_new_class;

    my $method      = $self->method;
    my $method_name = $method->name;
    my %sig         = $method->get_signature;

    if (@ARGV) {
        $self->die( "extra args detected: @ARGV");
    }
    
    return $obj->$method_name(%sig);
}

1;
