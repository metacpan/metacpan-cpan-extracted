package App::CPAN::Search;

use strict;
use warnings;

use CPAN;
use Getopt::Std;

our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

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
		return 1;
	}
	$self->{'_module_prefix'} = shift @ARGV;

	# Print all modules with prefix.
	# XXX Rewrite to something nice.
	CPAN::Shell->m("/^$self->{'_module_prefix'}/");

	return 0;
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
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::CPAN::Search->new;

Constructor.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::CPAN::Search;

 # Arguments.
 @ARGV = (
         'Library',
 );

 # Run.
 exit App::CPAN::Search->new->run;

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
L<Getopt::Std>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-CPAN-Search>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2015-2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
