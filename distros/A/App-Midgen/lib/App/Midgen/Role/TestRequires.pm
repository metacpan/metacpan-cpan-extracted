package App::Midgen::Role::TestRequires;

use constant {BLANK => q{ }, NONE => q{}, TWO => 2, THREE => 3,};

use Moo::Role;
requires
	qw( ppi_document develop debug verbose format xtest _process_found_modules meta2 );

use PPI;
use Try::Tiny;
use Data::Printer {caller_info => 1,};

# Load time and dependencies negate execution time
# use namespace::clean -except => 'meta';

our $VERSION = '0.34';
$VERSION = eval $VERSION;    ## no critic


#######
# composed method - xtests_test_requires
#######
sub xtests_test_requires {
	my $self = shift;
	my $phase_relationship = shift || NONE;

	my @modules;
	my @version_strings;

	#  PPI::Statement::Include
	#    PPI::Token::Word  	'use'
	#    PPI::Token::Whitespace  	' '
	#    PPI::Token::Word  	'Test::Requires'
	#    PPI::Token::Whitespace  	' '
	#    PPI::Structure::Constructor  	{ ... }
	#      PPI::Token::Whitespace  	' '
	#      PPI::Statement
	#        PPI::Token::Quote::Single  	''Test::Pod''
	#        PPI::Token::Whitespace  	' '
	#        PPI::Token::Operator  	'=>'
	#        PPI::Token::Whitespace  	' '
	#        PPI::Token::Number::Float  	'1.46'
	#      PPI::Token::Whitespace  	' '
	#    PPI::Token::Structure  	';'

	try {
		my @chunks
			= @{$self->ppi_document->find('PPI::Statement::Include') || []};

		foreach my $hunk (@chunks) {

			# test for use
			if (
				$hunk->find(
					sub {
						$_[1]->isa('PPI::Token::Word')
							and $_[1]->content =~ m{\A(?:use)\z};
					}
				)
				)
			{

				# test for Test::Requires
				if (
					$hunk->find(
						sub {
							$_[1]->isa('PPI::Token::Word')
								and $_[1]->content =~ m{\A(?:Test::Requires)\z};
						}
					)
					)
				{

					foreach (0 .. $#{$hunk->{children}}) {

						# looking for use Test::Requires { 'Test::Pod' => '1.46' };
						if ($hunk->{children}[$_]->isa('PPI::Structure::Constructor')) {

							my $ppi_sc = $hunk->{children}[$_]
								if $hunk->{children}[$_]->isa('PPI::Structure::Constructor');

							foreach (0 .. $#{$ppi_sc->{children}}) {

								if ($ppi_sc->{children}[$_]->isa('PPI::Statement')) {

									my $ppi_s = $ppi_sc->{children}[$_]
										if $ppi_sc->{children}[$_]->isa('PPI::Statement');

									foreach my $element (@{$ppi_s->{children}}) {

										# extract module name
										if ( $element->isa('PPI::Token::Quote::Double')
											|| $element->isa('PPI::Token::Quote::Single')
											|| $element->isa('PPI::Token::Word'))
										{
											my $module_name = $element->content;
											$module_name =~ s/(?:'|")//g;
											if ($module_name =~ m/\A(?:[a-zA-Z])/) {
												print "found module - $module_name\n" if $self->debug;
												push @modules, $module_name;
												$version_strings[$#modules] = undef;
											}
										}

										# extract version string
										if ( $element->isa('PPI::Token::Number::Float')
											|| $element->isa('PPI::Token::Quote::Double')
											|| $element->isa('PPI::Token::Quote::Single'))
										{
											my $version_string = $element->content;
											$version_string =~ s/(?:'|")//g;
											if ($version_string =~ m/\A(?:[0-9])/) {

												$version_string
													= version::is_lax($version_string)
													? $version_string
													: 0;

												print "found version string - $version_string\n"
													if $self->debug;
												$self->{found_version}{$modules[$#modules]}
													= $version_string;
												$version_strings[$#modules] = $version_string;
											}
										}
									}
								}
							}
						}

						# looking for use Test::Requires qw(MIME::Types);
						if ($hunk->{children}[$_]->isa('PPI::Token::QuoteLike::Words')) {

							my $ppi_tqw = $hunk->{children}[$_]
								if $hunk->{children}[$_]->isa('PPI::Token::QuoteLike::Words');

							my $operator = $ppi_tqw->{operator};
							my @type = split(//, $ppi_tqw->{sections}->[0]->{type});

							my $module = $ppi_tqw->{content};
							$module =~ s/$operator//;
							my $type_open = '\A\\' . $type[0];

							$module =~ s{$type_open}{};
							my $type_close = '\\' . $type[1] . '\Z';

							$module =~ s{$type_close}{};
							push @modules, split(BLANK, $module);
							$version_strings[$#modules] = undef;
						}
					}
				}
			}
		}
	};

	@version_strings = map { defined $_ ? $_ : 0 } @version_strings;
	p @modules         if $self->debug;
	p @version_strings if $self->debug;

	if (scalar @modules > 0) {

		for (0 .. $#modules) {
			print
				"Info: TestRequires -> Sending $modules[$_] - $version_strings[$_]\n"
				if ($self->verbose == TWO);
			try {
				$self->_process_found_modules(
					$phase_relationship, $modules[$_], $version_strings[$_],
					__PACKAGE__,         $phase_relationship,
				);
			};
		}
	}
	return;
}

no Moo::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Midgen::Role::TestRequires - extra checks for test files, looking
for methods in use L<Test::Requires> blocks, used by L<App::Midgen>

=head1 VERSION

version: 0.34

=head1 METHODS

=over 4

=item * xtests_test_requires

Checking for the following, extracting module name and version string.

 use Test::Requires { 'Test::Pod' => 1.46 };
 use Test::Requires { 'Test::Extra' => 1.46 };
 use Test::Requires qw[MIME::Types];
 use Test::Requires qw(IO::Handle::Util LWP::Protocol::http10);
 use Test::Requires {
   "Test::Test1" => '1.01',
   'Test::Test2' => 2.02,
 };

Used to check files in t/ and xt/ directories.

=back

=head1 AUTHOR

See L<App::Midgen>

=head2 CONTRIBUTORS

See L<App::Midgen>

=head1 COPYRIGHT

See L<App::Midgen>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
