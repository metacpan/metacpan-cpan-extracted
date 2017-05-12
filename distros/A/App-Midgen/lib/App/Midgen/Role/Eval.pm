package App::Midgen::Role::Eval;

use constant {NONE => q{}, TWO => 2,};
use Moo::Role;
requires
	qw( ppi_document debug verbose format xtest _process_found_modules develop meta2 );

use Try::Tiny;
use Data::Printer {caller_info => 1,};
use List::MoreUtils qw(any firstidx);

# Load time and dependencies negate execution time
# use namespace::clean -except => 'meta';

our $VERSION = '0.34';
$VERSION = eval $VERSION;    ## no critic

#######
# composed method - xtests_eval
#######
sub xtests_eval {
	my $self = shift;
	my $phase_relationship = shift || NONE;

	my @modules;
	my @version_strings;

#PPI::Document
#  PPI::Statement::Sub
#    PPI::Token::Word  	'sub'
#    PPI::Token::Whitespace  	' '
#    PPI::Token::Word  	'_assert_ssl'
#    PPI::Token::Whitespace  	' '
#    PPI::Structure::Block  	{ ... }
#      PPI::Token::Whitespace  	'\n'
#      PPI::Token::Whitespace  	'\t\t'
#      PPI::Statement
#        PPI::Token::Word  	'eval'
#        PPI::Token::Whitespace  	' '
#        PPI::Structure::Block  	{ ... }
#          PPI::Token::Whitespace  	' '
#          PPI::Statement::Include
#            PPI::Token::Word  	'require'
#            PPI::Token::Whitespace  	' '
#            PPI::Token::Word  	'IO::Socket::SSL'
#            PPI::Token::Structure  	';'
#          PPI::Token::Whitespace  	' '
#          PPI::Statement
#            PPI::Token::Word  	'IO::Socket::SSL'
#            PPI::Token::Operator  	'->'
#            PPI::Token::Word  	'VERSION'
#            PPI::Structure::List  	( ... )
#              PPI::Statement::Expression
#                PPI::Token::Number::Float  	'1.44'
#          PPI::Token::Whitespace  	' '
#        PPI::Token::Structure  	';'
#      PPI::Token::Whitespace  	'\n'

	try {

		my @chunks3 = @{$self->ppi_document->find('PPI::Statement::Sub')};

		foreach my $chunk (@chunks3) {
			if (
				$chunk->find(
					sub {
						$_[1]->isa('PPI::Token::Word')
							and $_[1]->content =~ m{\A(?:sub)\z};
					}
				)
				)
			{
				my $module_name;
				my $version_string;
				for (0 .. $#{$chunk->{children}}) {
					if ($chunk->{children}[$_]->isa('PPI::Structure::Block')) {
						my $ppi_sb = $chunk->{children}[$_]
							if $chunk->{children}[$_]->isa('PPI::Structure::Block');
						for (0 .. $#{$ppi_sb->{children}}) {
							if ($ppi_sb->{children}[$_]->isa('PPI::Statement')) {
								my $ppi_s = $ppi_sb->{children}[$_]
									if $ppi_sb->{children}[$_]->isa('PPI::Statement');
								my @chunks3 = @{$ppi_s->{children}};
								if (
									any {
										$_->isa('PPI::Token::Word')
											and $_->content =~ m{\A(?:eval|try)\z};
									}
									@{$ppi_s->{children}}
									)
								{
									my @ppisb = firstidx {
										$_->isa('PPI::Structure::Block');
									}
									@{$ppi_s->{children}};

									# extract first Structure::Block
									my $ppi_sb = $ppisb[0];

									$self->_eval_info($ppi_sb, \$module_name, \$version_string);

									print "Option3 $module_name - $version_string\n"
										if $self->debug;


									if (version::is_lax($version_string)) {

										push @modules, $module_name;
										$version_string
											= version::is_lax($version_string)
											? $version_string
											: 0;
										push @version_strings, $version_string;
										$self->{found_version}{$module_name} = $version_string;
									}
								}
							}
						}
					}
				}
			}
		}
	};


#PPI::Document
#  PPI::Statement
#    PPI::Token::Word  	'eval'
#    PPI::Token::Whitespace  	' '
#    PPI::Structure::Block  	{ ... }
#      PPI::Statement::Include
#        PPI::Token::Word  	'require'
#        PPI::Token::Whitespace  	' '
#        PPI::Token::Word  	'PAR::Dist'
#        PPI::Token::Structure  	';'
#      PPI::Token::Whitespace  	' '
#      PPI::Statement
#        PPI::Token::Word  	'PAR::Dist'
#        PPI::Token::Operator  	'->'
#        PPI::Token::Word  	'VERSION'
#        PPI::Structure::List  	( ... )
#          PPI::Statement::Expression
#            PPI::Token::Number::Float  	'0.17'

	try {
		my @chunks2 = @{$self->ppi_document->find('PPI::Statement')};
		foreach my $chunk (@chunks2) {
			if (
				$chunk->find(
					sub {
						$_[1]->isa('PPI::Token::Word')
							and $_[1]->content =~ m{\A(?:eval|try)\z};
					}
				)
				)
			{
				for (0 .. $#{$chunk->{children}}) {

					my $module_name;
					my $version_string;

					if ($chunk->{children}[$_]->isa('PPI::Structure::Block')) {

						my $ppi_sb = $chunk->{children}[$_]
							if $chunk->{children}[$_]->isa('PPI::Structure::Block');

						$self->_eval_info($ppi_sb, \$module_name, \$version_string);
						print "Option2 $module_name - $version_string\n" if $self->debug;
					}
					if (version::is_lax($version_string)) {

						push @modules, $module_name;
						$version_string
							= version::is_lax($version_string) ? $version_string : 0;
						push @version_strings, $version_string;
						$self->{found_version}{$module_name} = $version_string;
					}
				}
			}
		}
	};


	#PPI::Document
	#  PPI::Statement
	#    PPI::Token::Word  	'eval'
	#    PPI::Token::Whitespace  	' '
	#    PPI::Token::Quote::Double  	'"require Test::Kwalitee::Extra $mod_ver"'
	#    PPI::Token::Structure  	';'
	#

	try {
		my @chunks1 = @{$self->ppi_document->find('PPI::Statement')};
		foreach my $chunk (@chunks1) {
			if (
				$chunk->find(
					sub {
						$_[1]->isa('PPI::Token::Word')
							and $_[1]->content =~ m{\A(?:eval|try)\z};
					}
				)
				)
			{
				for (0 .. $#{$chunk->{children}}) {

					# ignore sub blocks - false positive
					last if $chunk->{children}[$_]->content eq 'sub';

					if ( $chunk->{children}[$_]->isa('PPI::Token::Quote::Double')
						|| $chunk->{children}[$_]->isa('PPI::Token::Quote::Single'))
					{
						my $eval_line = $chunk->{children}[$_]->content;

						$eval_line =~ s/(?:'|"|{|})//g;
						my @eval_includes = split /;/, $eval_line;

						foreach my $eval_include (@eval_includes) {

							$self->_mod_ver(\@modules, \@version_strings, $eval_include);
						}
					}

					if ($chunk->{children}[$_]->isa('PPI::Structure::Block')) {
						my @children = $chunk->{children}[$_]->children;

						foreach my $child_element (@children) {
							if ($child_element->isa('PPI::Statement::Include')) {

								my $eval_line = $child_element->content;
								my @eval_includes = split /;/, $eval_line;
								foreach my $eval_include (@eval_includes) {
									$self->_mod_ver(\@modules, \@version_strings,
										$eval_include);
								}
							}
						}
					}
				}
			}
		}
	};

	p @modules         if $self->debug;
	p @version_strings if $self->debug;

	if (scalar @modules > 0) {
		for (0 .. $#modules) {
			print "Info: Eval -> Sending $modules[$_] - $version_strings[$_]\n"
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


#######
# composed Method
#######
sub _mod_ver {
	my ($self, $modules, $version_strings, $eval_include) = @_;

	if ($eval_include =~ /^\s*(?:use|require|no)/) {

		$eval_include =~ s/^\s*(?:use|require|no)\s*//;

		my $module_name = $eval_include;

		$module_name =~ s/(?:\s[\s|\w|\n|.|;]+)$//;
		$module_name =~ s/\s+(?:[\$|\w|\n]+)$//;
		$module_name =~ s/\s+$//;

		$module_name =~ m/\A([\w|:]+)\b/;
		$module_name = $1;

		# exit if already found by this extra scanner
		return if $self->{found_version}{$module_name};

		# check for first char upper in module name
		push @{$modules}, $module_name if $module_name =~ m{\A(?:[a-zA-Z])};


		my $version_string = $eval_include;
		$version_string =~ s/$module_name\s*//;
		$version_string =~ s/\s*$//;
		$version_string =~ s/[a-zA-Z]|\s|\$|s|:|;//g;

		$version_string = version::is_lax($version_string) ? $version_string : 0;
		push @{$version_strings}, $version_string;
		$self->{found_version}{$module_name} = $version_string;
		print "Option1 $module_name - $version_string\n" if $self->debug;
	}

	return;
}


#######
# composed Method
#######
sub _eval_info {
	my ($self, $ppi_sb, $mn_ref, $vs_ref) = @_;

	for (0 .. $#{$ppi_sb->{children}}) {

		# find module name
		if ($ppi_sb->{children}[$_]->isa('PPI::Statement::Include')) {
			my $ppi_si = $ppi_sb->{children}[$_]
				if $ppi_sb->{children}[$_]->isa('PPI::Statement::Include');
			if ( $ppi_si->{children}[0]->isa('PPI::Token::Word')
				&& $ppi_si->{children}[0]->content eq 'require')
			{
				${$mn_ref} = $ppi_si->{children}[2]->content
					if $ppi_si->{children}[2]->isa('PPI::Token::Word');
			}
		}

		# find version string if we previously found a name
		if ($ppi_sb->{children}[$_]->isa('PPI::Statement')) {
			my $ppi_s = $ppi_sb->{children}[$_]
				if $ppi_sb->{children}[$_]->isa('PPI::Statement');
			if (
				(
					    $ppi_s->{children}[0]->isa('PPI::Token::Word')
					and $ppi_s->{children}[0]->content eq ${$mn_ref}
				)
				&& (  $ppi_s->{children}[2]->isa('PPI::Token::Word')
					and $ppi_s->{children}[2]->content eq 'VERSION')
				)
			{
				my $ppi_sl = $ppi_s->{children}[3]
					if $ppi_s->{children}[3]->isa('PPI::Structure::List');
				${$vs_ref} = $ppi_sl->{children}[0]->{children}[0]->content;
			}
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

App::Midgen::Roles::Eval - used by L<App::Midgen>

=head1 VERSION

This document describes App::Midgen::Roles version: 0.34

=head1 METHODS

=over 4

=item * xtests_eval

Checking for the following, extracting module name and version string.

  eval {use Test::Kwalitee::Extra 0.000007};
  eval {use Moo 1.002; 1;};
  eval { no Moose; 1; };
  eval { require Moose };
  my $HAVE_MOOSE = eval { require Moose; 1; };

  try { no Moose; 1; };
  try { require Moose };
  my $HAVE_MOOSE = try { require Moose; 1; };

  eval {require PAR::Dist; PAR::Dist->VERSION(0.17)}

=back

=head1 SEE ALSO

L<App::Midgen>,

=head1 AUTHOR

See L<App::Midgen>

=head2 CONTRIBUTORS

See L<App::Midgen>

=head1 COPYRIGHT

See L<App::Midgen>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


