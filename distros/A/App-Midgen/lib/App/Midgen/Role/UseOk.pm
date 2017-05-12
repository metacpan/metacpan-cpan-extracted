package App::Midgen::Role::UseOk;

use constant {BLANK => q{ }, NONE => q{}, TWO => 2, THREE => 3,};

use Moo::Role;
requires
	qw( ppi_document debug verbose format xtest _process_found_modules develop meta2 );

# Load time and dependencies negate execution time
# use namespace::clean -except => 'meta';

our $VERSION = '0.34';
$VERSION = eval $VERSION;    ## no critic

use PPI;
use Try::Tiny;
use Data::Printer {caller_info => 1,};
use Tie::Static qw(static);

#use List::MoreUtils qw( lastidx );

#######
# composed method - _xtests_in_single_quote
#######
sub xtests_use_ok {
	my $self = shift;
	my $phase_relationship = shift || NONE;
	my @modules;
	my @version_strings;

	#PPI::Document
	#  PPI::Statement::Scheduled
	#    PPI::Token::Word  	'BEGIN'
	#    PPI::Token::Whitespace  	' '
	#    PPI::Structure::Block  	{ ... }
	#      PPI::Token::Whitespace  	'\n'
	#      PPI::Token::Whitespace  	'\t'
	#      PPI::Statement
	#        PPI::Token::Word  	'use_ok'
	#        PPI::Structure::List  	( ... )
	#          PPI::Token::Whitespace  	' '
	#          PPI::Statement::Expression
	#            PPI::Token::Quote::Single  	''Term::ReadKey''
	#            PPI::Token::Operator  	','
	#            PPI::Token::Whitespace  	' '
	#            PPI::Token::Quote::Single  	''2.30''

	my @chunks =

		map  { [$_->schildren] }
		grep { $_->child(0)->literal =~ m{\A(?:BEGIN)\z} }
		grep { $_->child(0)->isa('PPI::Token::Word') }
		@{$self->ppi_document->find('PPI::Statement::Scheduled') || []};

	foreach my $hunk (@chunks) {

		# looking for use_ok { 'Term::ReadKey' => '2.30' };
		if (grep { $_->isa('PPI::Structure::Block') } @$hunk) {

			# hack for List
			my @hunkdata = @$hunk;

			foreach my $ppi_sb (@hunkdata) {
				if ($ppi_sb->isa('PPI::Structure::Block')) {
					foreach my $ppi_s (@{$ppi_sb->{children}}) {
						if ($ppi_s->isa('PPI::Statement')) {
							p $ppi_s if $self->debug;
							if ($ppi_s->{children}[0]->content eq 'use_ok') {
								my $ppi_sl = $ppi_s->{children}[1];
								foreach my $ppi_se (@{$ppi_sl->{children}}) {
									if ($ppi_se->isa('PPI::Statement::Expression')) {
										foreach my $element (@{$ppi_se->{children}}) {

											# some fudge to remember the module name if falied
											static \my $previous_module;
											if ( $element->isa('PPI::Token::Quote::Single')
												|| $element->isa('PPI::Token::Quote::Double'))
											{

												my $module = $element->content;
												$module =~ s/^(?:['|"])//;
												$module =~ s/(?:['|"])$//;
												if ($module =~ m{\A(?:[[a-zA-Z])}) {

													print "found module - $module\n" if $self->debug;
													push @modules, $module;
													$version_strings[$#modules] = undef;
													$previous_module = $module;
												}
											}


											if ( $element->isa('PPI::Token::Number::Float')
												|| $element->isa('PPI::Token::Quote::Single')
												|| $element->isa('PPI::Token::Quote::Double'))
											{

												my $version_string = $element->content;

												$version_string =~ s/^(?:['|"])//;
												$version_string =~ s/(?:['|"])$//;
												next if $version_string !~ m{\A(?:[\d|v])};

												$version_string
													= version::is_lax($version_string)
													? $version_string
													: 0;

												print "found version_string - $version_string\n"
													if $self->debug;
												try {
													if ($previous_module) {
														$self->{found_version}{$previous_module}
															= $version_string;
														$version_strings[$#modules] = $version_string;
													}

													$previous_module = undef;
												};
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}

	@version_strings = map { defined $_ ? $_ : 0 } @version_strings;
	p @modules         if $self->debug;
	p @version_strings if $self->debug;

	if (scalar @modules > 0) {

		for (0 .. $#modules) {
			print "Info: UseOk -> Sending $modules[$_] - $version_strings[$_]\n"
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

App::Midgen::Roles::UseOk - extra checks for test files, looking
for methods in use_ok in BEGIN blocks, used by L<App::Midgen>

=head1 VERSION

version: 0.34

=head1 METHODS

=over 4

=item * xtests_use_ok

Checking for the following, extracting module name and version string.

 BEGIN {
   use_ok( 'Term::ReadKey', '2.30' );
   use_ok( 'Term::ReadLine', '1.10' );
   use_ok( 'Fred::BloggsOne', '1.01' );
   use_ok( "Fred::BloggsTwo", "2.02" );
   use_ok( 'Fred::BloggsThree', 3.03 );
 }

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
