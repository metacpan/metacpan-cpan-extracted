package App::CPAN::Search;

use strict;
use warnings;

use CPAN;
use Class::Utils qw(set_params);
use Getopt::Std;

our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process params.
	set_params($self, @params);

	# Process arguments.
	$self->{'_opts'} = {
		'h' => 0,
	};
	if (! getopts('h', $self->{'_opts'}) || @ARGV < 1
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-h] [--version] module_prefix\n";
		print STDERR "\t-h\t\tHelp.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tmodule_prefix\tModule prefix. e.g. ".
			"Module::Install\n";
		exit 1;
	}
	$self->{'_module_prefix'} = shift @ARGV;

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Print all modules with prefix.
	# XXX Rewrite to something nice.
	CPAN::Shell->m("/^$self->{'_module_prefix'}/");

	return;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::CPAN::Search - Base class for cpan-search script.

=head1 SYNOPSIS

 use App::CPAN::Search;
 my $app = App::CPAN::Search->new;
 $app->run;

=head1 METHODS

=over 8

=item C<new()>

 Constructor.

=item C<run()>

 Run method.
 Returns undef.

=back

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::CPAN::Search;

 # Arguments.
 @ARGV = (
         'Library',
 );

 # Run.
 App::CPAN::Search->new->run;

 # Output like:
 # Reading '/home/skim/.local/share/.cpan/Metadata'
 #   Database was generated on Tue, 29 Dec 2015 21:53:32 GMT
 # Module id = Library::CallNumber::LC
 #     CPAN_USERID  DBWELLS (Dan Wells <CENSORED>)
 #     CPAN_VERSION 0.23
 #     CPAN_FILE    D/DB/DBWELLS/Library-CallNumber-LC-0.23.tar.gz
 #     MANPAGE      Library::CallNumber::LC - Deal with Library-of-Congress call numbers
 #     INST_FILE    /home/skim/perl5/lib/perl5/Library/CallNumber/LC.pm
 #     INST_VERSION 0.23

=head1 DEPENDENCIES

L<CPAN>,
L<Class::Utils>,
L<Getopt::Std>.

=head1 REPOSITORY

L<https://github.com/tupinek/App-CPAN-Search>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2015-2018 Michal Josef Špaček
 BSD 2-Clause License

=head1 VERSION

0.03

=cut
