=head1 NAME

CLIPSeqTools::Role::Option::OutputPrefix - Role to enable output prefix as command line option.

=head1 SYNOPSIS

Role to enable output prefix as command line option.

  Defines options.
      -o_prefix <Str>              output path prefix. If path does not exist it will be created. Default: ./

  Provides methods.
      make_path_for_output_prefix  creates the path for the output prefix if it does not exist. eg foo/bar.txt will create foo/

=cut


package CLIPSeqTools::Role::Option::OutputPrefix;
$CLIPSeqTools::Role::Option::OutputPrefix::VERSION = '0.1.7';

#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use MooseX::App::Role;
use File::Path qw(make_path);
use File::Spec;


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'o_prefix' => (
	is            => 'rw',
	isa           => 'Str',
	default       => './',
	documentation => 'output path prefix. Program will add an extension to prefix. If path does not exist it will be created.',
);


#######################################################################
########################   Interface Methods   ########################
#######################################################################
sub make_path_for_output_prefix {
	my ($self) = @_;
	
	my (undef, $directory, undef) = File::Spec->splitpath($self->o_prefix);
	make_path($directory);
}

sub validate_args {}


1;
