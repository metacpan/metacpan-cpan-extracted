package App::Midgen::Role::UseModule;

use constant {BLANK => q{ }, TRUE => 1, FALSE => 0, NONE => q{}, TWO => 2,
	THREE => 3,};

use Moo::Role;
requires
	qw( ppi_document debug verbose format xtest _process_found_modules develop meta2 );

our $VERSION = '0.34';
$VERSION = eval $VERSION;    ## no critic

use PPI;
use Data::Printer {caller_info => 1,};
use Try::Tiny;
use Tie::Static qw(static);


#######
# composed method - _xtests_in_single_quote
#######
sub xtests_use_module {
	my $self = shift;
	my $phase_relationship = shift || NONE;

	my @modules;
	my @version_strings;

# bug out if there is no Include for Module::Runtime found
	return if $self->_is_module_runtime() eq FALSE;

##	say 'Option 1: use_module( M::N )...';

#
# use_module("Math::BigInt", 1.31)->new("1_234");
#
#PPI::Document
#  PPI::Statement
#	 PPI::Token::Whitespace  	' '
#    PPI::Token::Word  	'use_module'
#    PPI::Structure::List  	( ... )
#      PPI::Statement::Expression
#        PPI::Token::Quote::Double  	'"Math::BigInt"'
#        PPI::Token::Operator  	','
#        PPI::Token::Whitespace  	' '
#        PPI::Token::Number::Float  	'1.31'
#    PPI::Token::Operator  	'->'
#    PPI::Token::Word  	'new'
#    PPI::Structure::List  	( ... )
#      PPI::Statement::Expression
#        PPI::Token::Quote::Double  	'"1_234"'
#    PPI::Token::Structure  	';'
#  PPI::Token::Whitespace  	'\n'

	try {
		my @chunks1 = @{$self->ppi_document->find('PPI::Statement')};

		foreach my $chunk (@chunks1) {

			if (not $chunk->find(sub { $_[1]->isa('PPI::Token::Symbol') })) {

				# test for module-runtime key-words
				if (
					$chunk->find(
						sub {
							$_[1]->isa('PPI::Token::Word')
								and $_[1]->content
								=~ m{\A[Module::Runtime::]*(?:use_module|use_package_optimistically|require_module)\z};
						}
					)
					)
				{
					if (
						not $chunk->find(
							sub {
								$_[1]->isa('PPI::Token::Word')
									and $_[1]->content =~ m{\A(?:return)\z};
							}
						)
						)
					{

						for (0 .. $#{$chunk->{children}}) {

							# find all ppi_sl
							if ($chunk->{children}[$_]->isa('PPI::Structure::List')) {

								my $ppi_sl = $chunk->{children}[$_]
									if $chunk->{children}[$_]->isa('PPI::Structure::List');

								print "Option 1: use_module( M::N )...\n" if $self->debug;
								$self->_module_names_ppi_sl($ppi_sl, \@modules,
									\@version_strings);
							}
						}
					}
				}
			}
		}
	};


##	say 'Option 2: my $q = use_module( M::N )...';


#
# my $bi = use_module("Math::BigInt", 1.31)->new("1_234");
#
#PPI::Document
#  PPI::Statement::Variable
#    PPI::Token::Word  	'my'
#    PPI::Token::Whitespace  	' '
#    PPI::Token::Symbol  	'$bi'
#    PPI::Token::Whitespace  	' '
#    PPI::Token::Operator  	'='
#    PPI::Token::Whitespace  	' '
#    PPI::Token::Word  	'use_module'
#    PPI::Structure::List  	( ... )
#      PPI::Statement::Expression
#        PPI::Token::Quote::Double  	'"Math::BigInt"'
#        PPI::Token::Operator  	','
#        PPI::Token::Whitespace  	' '
#        PPI::Token::Number::Float  	'1.31'
#    PPI::Token::Operator  	'->'
#    PPI::Token::Word  	'new'
#    PPI::Structure::List  	( ... )
#      PPI::Statement::Expression
#        PPI::Token::Quote::Double  	'"1_234"'
#    PPI::Token::Structure  	';'
#  PPI::Token::Whitespace  	'\n'


	try {
		# let's extract all ppi_sv
		my @chunks2 = @{$self->ppi_document->find('PPI::Statement::Variable')};
		foreach my $chunk (@chunks2) {

			# test for my
			if (
				$chunk->find(
					sub {
						$_[1]->isa('PPI::Token::Word')
							and $_[1]->content =~ m{\A(?:my)\z};
					}
				)
				)
			{
				# test for module-runtime key-words
				if (
					$chunk->find(
						sub {
							$_[1]->isa('PPI::Token::Word')
								and $_[1]->content
								=~ m{\A[Module::Runtime::]*(?:use_module|use_package_optimistically)\z};
						}
					)
					)
				{
					for (0 .. $#{$chunk->{children}}) {

						# find all ppi_sl
						if ($chunk->{children}[$_]->isa('PPI::Structure::List')) {

							my $ppi_sl = $chunk->{children}[$_]
								if $chunk->{children}[$_]->isa('PPI::Structure::List');

							print "Option 2: my \$q = use_module( M::N )...\n"
								if $self->debug;
							$self->_module_names_ppi_sl($ppi_sl, \@modules,
								\@version_strings);


						}
					}
				}
			}
		}
	};


##	say 'Option 3: $q = use_module( M::N )...';

#
# $bi = use_module("Math::BigInt", 1.31)->new("1_234");
#
#PPI::Document
#  PPI::Statement
#    PPI::Token::Symbol  	'$bi'
#    PPI::Token::Whitespace  	' '
#    PPI::Token::Operator  	'='
#    PPI::Token::Whitespace  	' '
#    PPI::Token::Word  	'use_module'
#    PPI::Structure::List  	( ... )
#      PPI::Statement::Expression
#        PPI::Token::Quote::Double  	'"Math::BigInt"'
#        PPI::Token::Operator  	','
#        PPI::Token::Whitespace  	' '
#        PPI::Token::Number::Float  	'1.31'
#    PPI::Token::Operator  	'->'
#    PPI::Token::Word  	'new'
#    PPI::Structure::List  	( ... )
#      PPI::Statement::Expression
#        PPI::Token::Quote::Double  	'"1_234"'
#    PPI::Token::Structure  	';'
#  PPI::Token::Whitespace  	'\n'

	try {
		my @chunks1 = @{$self->ppi_document->find('PPI::Statement')};

		foreach my $chunk (@chunks1) {

			# test for not my
			if (
				not $chunk->find(
					sub {
						$_[1]->isa('PPI::Token::Word')
							and $_[1]->content =~ m{\A(?:my)\z};
					}
				)
				)
			{

				if ($chunk->find(sub { $_[1]->isa('PPI::Token::Symbol') })) {

					if (
						$chunk->find(
							sub {
								$_[1]->isa('PPI::Token::Operator') and $_[1]->content eq '=';
							}
						)
						)
					{

						# test for module-runtime key-words
						if (
							$chunk->find(
								sub {
									$_[1]->isa('PPI::Token::Word')
										and $_[1]->content
										=~ m{\A[Module::Runtime::]*(?:use_module|use_package_optimistically)\z};
								}
							)
							)
						{
							for (0 .. $#{$chunk->{children}}) {

								# find all ppi_sl
								if ($chunk->{children}[$_]->isa('PPI::Structure::List')) {

									my $ppi_sl = $chunk->{children}[$_]
										if $chunk->{children}[$_]->isa('PPI::Structure::List');

									print "Option 3: \$q = use_module( M::N )...\n"
										if $self->debug;
									$self->_module_names_ppi_sl($ppi_sl, \@modules,
										\@version_strings);

								}
							}
						}
					}
				}
			}
		}
	};


##	say 'Option 4: return use_module( M::N )...';

#
# return use_module(\'App::SCS::PageSet\')->new(
# base_dir => $self->share_dir->catdir(\'pages\'),
# plugin_config => $self->page_plugin_config,
# );
#
#PPI::Document
#  PPI::Statement::Break
#    PPI::Token::Word  	'return'
#    PPI::Token::Whitespace  	' '
#    PPI::Token::Word  	'use_module'
#    PPI::Structure::List  	( ... )
#      PPI::Statement::Expression
#        PPI::Token::Quote::Single  	''App::SCS::PageSet''
#    PPI::Token::Operator  	'->'
#    PPI::Token::Word  	'new'
#    PPI::Structure::List  	( ... )
#      PPI::Token::Whitespace  	'\n'
#      PPI::Token::Whitespace  	'    '
#      PPI::Statement::Expression
#        PPI::Token::Word  	'base_dir'
#        PPI::Token::Whitespace  	' '
#        PPI::Token::Operator  	'=>'
#        PPI::Token::Whitespace  	' '
#        PPI::Token::Symbol  	'$self'
#        PPI::Token::Operator  	'->'
#        PPI::Token::Word  	'share_dir'
#        PPI::Token::Operator  	'->'
#        PPI::Token::Word  	'catdir'
#        PPI::Structure::List  	( ... )
#          PPI::Statement::Expression
#            PPI::Token::Quote::Single  	''pages''
#        PPI::Token::Operator  	','
#        PPI::Token::Whitespace  	'\n'
#        PPI::Token::Whitespace  	'    '
#        PPI::Token::Word  	'plugin_config'
#        PPI::Token::Whitespace  	' '
#        PPI::Token::Operator  	'=>'
#        PPI::Token::Whitespace  	' '
#        PPI::Token::Symbol  	'$self'
#        PPI::Token::Operator  	'->'
#        PPI::Token::Word  	'page_plugin_config'
#        PPI::Token::Operator  	','
#      PPI::Token::Whitespace  	'\n'
#      PPI::Token::Whitespace  	'  '
#    PPI::Token::Structure  	';'

	try {
		my @chunks4 = @{$self->ppi_document->find('PPI::Statement::Break')};

		for my $chunk (@chunks4) {

			if (
				$chunk->find(
					sub {
						$_[1]->isa('PPI::Token::Word')
							and $_[1]->content =~ m{\A(?:return)\z};
					}
				)
				)
			{

				if (
					$chunk->find(
						sub {
							$_[1]->isa('PPI::Token::Word')
								and $_[1]->content
								=~ m{\A[Module::Runtime::]*(?:use_module|use_package_optimistically)\z};
						}
					)
					)
				{
					for (0 .. $#{$chunk->{children}}) {

						# find all ppi_sl
						if ($chunk->{children}[$_]->isa('PPI::Structure::List')) {
							my $ppi_sl = $chunk->{children}[$_]
								if $chunk->{children}[$_]->isa('PPI::Structure::List');
							print "Option 4: return use_module( M::N )...\n"
								if $self->debug;
							$self->_module_names_ppi_sl($ppi_sl, \@modules,
								\@version_strings,);


						}
					}
				}
			}
		}
	};

#	p @version_strings;
	@version_strings = map { defined $_ ? $_ : 0 } @version_strings;
	p @modules         if $self->debug;
	p @version_strings if $self->debug;
	if (scalar @modules > 0) {

		for (0 .. $#modules) {
			print "Info: UseModule -> Sending $modules[$_] - $version_strings[$_]\n"
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
# composed method test for include Module::Runtime
#######
sub _is_module_runtime {
	my $self                         = shift;
	my $module_runtime_include_found = FALSE;

#PPI::Document
#  PPI::Statement::Include
#    PPI::Token::Word  	'use'
#    PPI::Token::Whitespace  	' '
#    PPI::Token::Word  	'Module::Runtime'

	try {
		my $includes = $self->ppi_document->find('PPI::Statement::Include');
		if ($includes) {
			foreach my $include (@{$includes}) {
				next if $include->type eq 'no';
				if (not $include->pragma) {
					my $module = $include->module;

					if ($module eq 'Module::Runtime') {
						$module_runtime_include_found = TRUE;
						p $module if $self->debug;
					}
				}
			}
		}
	};
	p $module_runtime_include_found if $self->debug;
	return $module_runtime_include_found;

}


#######
# composed method extract module name from PPI::Structure::List
#######
sub _module_names_ppi_sl {
	my ($self, $ppi_sl, $mn_ref, $mv_ref) = @_;


	if ($ppi_sl->isa('PPI::Structure::List')) {

		static \my $previous_module;
		foreach my $ppi_se (@{$ppi_sl->{children}}) {
			for (0 .. $#{$ppi_se->{children}}) {

				if ( $ppi_se->{children}[$_]->isa('PPI::Token::Quote::Single')
					|| $ppi_se->{children}[$_]->isa('PPI::Token::Quote::Double'))
				{
					my $module = $ppi_se->{children}[$_]->content;
					$module =~ s/(?:['|"])//g;
					if ($module =~ m{\A(?:[a-zA-Z])}) {
						print "found module - $module\n" if $self->debug;
						push @{$mn_ref}, $module;
						$mv_ref->[$#{$mn_ref}] = undef;
						p @{$mn_ref} if $self->debug;
						$previous_module = $module;
					}
				}
				if ( $ppi_se->{children}[$_]->isa('PPI::Token::Number::Float')
					|| $ppi_se->{children}[$_]->isa('PPI::Token::Number::Version')
					|| $ppi_se->{children}[$_]->isa('PPI::Token::Quote::Single')
					|| $ppi_se->{children}[$_]->isa('PPI::Token::Quote::Double'))
				{
					my $version_string = $ppi_se->{children}[$_]->content;
					$version_string =~ s/(?:['|"])//g;
					next if $version_string !~ m{\A[\d|v]};

					$version_string
						= version::is_lax($version_string) ? $version_string : 0;

					print "Info: UseModule found version_string - $version_string\n"
						if $self->debug;

					try {
						if ($previous_module) {
							$self->{found_version}{$previous_module} = $version_string;
							$mv_ref->[$#{$mn_ref}] = $version_string;
						}
						p $version_string if $self->debug;
						$previous_module = undef;
					};
				}
			}
		}
	}
}


no Moo::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Midgen::Roles::UseModule - looking for methods with Module::Runtime
includes, used by L<App::Midgen>

=head1 VERSION

version: 0.34


=head1 METHODS

=over 4

=item * xtests_use_module

Checking for the following, extracting module name and version strings.

  use_module("Module::Name", x.xx)->new( ... );
  require_module( 'Module::Name');
  use_package_optimistically("Module::Name", x.xx)->new( ... );

  my $abc = use_module("Module::Name", x.xx)->new( ... );
  my $abc = use_package_optimistically("Module::Name", x.xx)->new( ... );

  $abc = use_module("Module::Name", x.xx)->new( ... );
  $abc = use_package_optimistically("Module::Name", x.xx)->new( ... );

  return use_module( 'Module::Name', x,xx )->new( ... );
  return use_package_optimisticall( 'Module::Name', x.xx )->new( ... );

We also support the prefix C<Module::Runtime::...> in the above.

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
