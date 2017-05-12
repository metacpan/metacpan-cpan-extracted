#-----------------------------------------------------------------
# App::testapp
#-----------------------------------------------------------------
use warnings;
use strict;

package App::testapp;
use parent 'App::Cmdline';

sub execute {
    my ($self, $opt, $args) = @_;
}

1;
__END__
# Define your own options, and add some predefined sets.
sub opt_spec {
    my $self = shift;
    return $self->check_for_duplicates (
        [ 'check|c' => "only check the configuration"  ],
	[],
	$self->composed_of (
	    'App::Cmdline::Options::ExtDB',
	    [],
	    'App::Cmdline::Options::Basic',
	)
        );
}

# sub opt_spec {
#     my $self = shift;
#     my @db_options = $self->composed_of ('App::Cmdline::Options::Basic');
#     pop @db_options;
#     return
# #	@db_options,
# #	[ 'latitude|y=s'  => "geographical latitude"  ],
# #	[ 'longitude|x=s' => "geographical longitude" ],
# #	[ 'xpoint|x'      => 'make an X point'],
# #	[ 'ypoint|y'      => 'make a  Y point'],
# 	[ 'number|n=i'    => 'expected number of arguments'],
# 	$self->composed_of (
# 	    'App::Cmdline::Options::ExtBasic',
# 	);
# }



# Use this for validating your options (and remaining arguments).
# sub validate_args {
#      my ($self, $opt, $args) = @_;
#      $self->SUPER::validate_args ($opt, $args);
#      if ($opt->number and scalar @$args != $opt->number) {
# 	 $self->usage_error ("Option --number does not correspond with the number of arguments");
#      }
#  }

# Use this for changing the first line of the Usage message.
# sub usage_desc {
#     my $self = shift;
#     return $self->SUPER::usage_desc() . " <some arguments...>";
# }

# Use this to change (App::Cmdline's) default configuration of Getopt::Long
#sub getopt_conf {
#    return [ 'bundling' ];
#}

#-----------------------------------------------------------------
# The main job is done here. Mandatory method.
#-----------------------------------------------------------------
sub execute {
    my ($self, $opt, $args) = @_;
}

1;
__END__

=pod

=head1 SYNOPSIS

   A synopsis.

=head1 DESCRIPTION

This is myapp.

=cut
