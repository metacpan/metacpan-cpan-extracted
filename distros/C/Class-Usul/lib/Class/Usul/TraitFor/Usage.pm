package Class::Usul::TraitFor::Usage;

use attributes ();
use namespace::autoclean;

use Class::Inspector;
use Class::Usul::Constants qw( FAILED FALSE NUL OK SPC TRUE );
use Class::Usul::File;
use Class::Usul::Functions qw( dash2under emit emit_to ensure_class_loaded
                               find_source is_member list_attr_of pad throw
                               untaint_cmdline untaint_identifier );
use Class::Usul::IPC;
use Class::Usul::Types     qw( Bool DataEncoding DataLumper ProcCommer );
use Scalar::Util           qw( blessed );
use Try::Tiny;
use Moo::Role;
use Class::Usul::Options;

requires qw( config dumper next_argv options_usage output quiet );

# Public attributes
option 'encoding'     => is => 'lazy', isa => DataEncoding,
   documentation      => 'Decode/encode input/output using this encoding',
   default            => sub { $_[ 0 ]->config->encoding }, format => 's';

option 'help_manual'  => is => 'ro',   isa => Bool, default => FALSE,
   documentation      => 'Displays the documentation for the program',
   short              => 'H';

option 'help_options' => is => 'ro',   isa => Bool, default => FALSE,
   documentation      => 'Describes program options and methods',
   short              => 'h';

option 'help_usage'   => is => 'ro',   isa => Bool, default => FALSE,
   documentation      => 'Displays this command line usage',
   short              => '?';

option 'show_version' => is => 'ro',   isa => Bool, default => FALSE,
   documentation      => 'Displays the version number of the program class';

has 'file'            => is => 'lazy', isa => DataLumper,
   builder            => sub { Class::Usul::File->new( builder => $_[ 0 ] ) };

has 'ipc'             => is => 'lazy', isa => ProcCommer,
   builder            => sub { Class::Usul::IPC->new( builder => $_[ 0 ] ) },
   handles            => [ 'run_cmd' ];

# Class attributes
my $_can_call_cache = {}; my $_method_cache = {};

# Private functions
my $_list_methods_of = sub {
   my $class = blessed $_[ 0 ] || $_[ 0 ];

   exists $_method_cache->{ $class } or $_method_cache->{ $class }
      = [ map  { s{ \A .+ :: }{}msx; $_ }
          grep { my $subr = $_;
                 grep { $_ eq 'method' } attributes::get( \&{ $subr } ) }
              @{ Class::Inspector->methods( $class, 'full', 'public' ) } ];

   return $_method_cache->{ $class };
};

my $_get_pod_header_for_method = sub {
   my ($class, $method) = @_;

   my $src = find_source $class
      or throw 'Class [_1] cannot find source', [ $class ];
   my $ev  = [ grep { $_->{content} =~ m{ (?: ^|[< ]) $method (?: [ >]|$ ) }msx}
               grep { $_->{type} eq 'command' }
                   @{ Pod::Eventual::Simple->read_file( $src ) } ]->[ 0 ];
   my $pod = $ev ? $ev->{content} : undef; $pod and chomp $pod;

   return $pod;
};

# Private methods
my $_apply_stdio_encoding = sub {
   my $self = shift; my $enc = untaint_cmdline $self->encoding;

   for (*STDIN, *STDOUT, *STDERR) {
      $_->opened or next; binmode $_, ":encoding(${enc})";
   }

   autoflush STDOUT TRUE; autoflush STDERR TRUE;
   return;
};

my $_get_classes_and_roles = sub {
   my $self = shift; my %uniq = (); ensure_class_loaded 'mro';

   my @classes = @{ mro::get_linear_isa( blessed $self ) };

   while (my $class = shift @classes) {
      $class = (split m{ __WITH__ }mx, $class)[ 0 ];
      $class =~ m{ ::_BASE \z }mx and next;
      $class =~ s{ \A Role::Tiny::_COMPOSABLE:: }{}mx;
      $uniq{ $class } and next; $uniq{ $class }++;

      exists $Role::Tiny::APPLIED_TO{ $class }
         and push @classes, keys %{ $Role::Tiny::APPLIED_TO{ $class } };
   }

   return [ sort keys %uniq ];
};

my $_man_page_from = sub {
   my ($self, $src) = @_; ensure_class_loaded 'Pod::Man';

   my $conf     = $self->config;
   my $parser   = Pod::Man->new( center  => $conf->doc_title || NUL,
                                 name    => $conf->script,
                                 release => 'Version '.$self->app_version,
                                 section => '3m' );
   my $cmd      = $conf->man_page_cmd || [];
   my $tempfile = $self->file->tempfile;

   $parser->parse_from_file( $src->pathname.NUL, $tempfile->pathname );
   emit $self->run_cmd( [ @{ $cmd }, $tempfile->pathname ] )->out;
   return OK;
};

my $_usage_for = sub {
   my ($self, $method) = @_; ensure_class_loaded 'Pod::Select';

   for my $class (@{ $self->$_get_classes_and_roles }) {
      is_member( $method, Class::Inspector->methods( $class, 'public' ) )
         or next;

      my $selector = Pod::Select->new(); my $tfile = $self->file->tempfile;

      $selector->select( "/(?:[A-Z][\<])?${method}.*" );
      $selector->parse_from_file( find_source $class, $tfile->pathname );
      $tfile->stat->{size} > 0 and return $self->$_man_page_from( $tfile );
   }

   emit_to \*STDERR, "Method ${method} no documentation found\n";
   return FAILED;
};

my $_output_usage = sub {
   my ($self, $verbose) = @_; my $method = $self->next_argv;

   defined $method and $method = untaint_identifier dash2under $method;

   $self->can_call( $method ) and return $self->$_usage_for( $method );

   $verbose > 1 and return $self->$_man_page_from( $self->config );

   ensure_class_loaded 'Pod::Usage'; $verbose > 0 and Pod::Usage::pod2usage
      ( { -exitval => OK,
          -input   => $self->config->pathname.NUL,
          -message => SPC,
          -verbose => $verbose } ); # Never returns

   emit_to \*STDERR, $self->options_usage;
   return FAILED;
};

# Construction
before 'BUILD' => sub {
   my $self = shift; $self->$_apply_stdio_encoding;

   $self->help_usage   and $self->exit_usage( 0 );
   $self->help_options and $self->exit_usage( 1 );
   $self->help_manual  and $self->exit_usage( 2 );
   $self->show_version and $self->exit_version;
   return;
};

# Public methods
sub app_version {
   my $self = shift; my $class = $self->config->appclass;

   my $ver  = try { ensure_class_loaded $class; $class->VERSION } catch { '?' };

   return $ver;
}

sub can_call {
   my ($self, $wanted) = @_; $wanted or return FALSE;

   exists $_can_call_cache->{ $wanted } or $_can_call_cache->{ $wanted }
      = (is_member $wanted, $_list_methods_of->( $self )) ? TRUE : FALSE;

   return $_can_call_cache->{ $wanted };
}

sub dump_config_attr : method {
   my $self = shift; my @except =
      qw( BUILDARGS BUILD inflate_path inflate_paths inflate_symbol new secret);

   $self->dumper( [ list_attr_of $self->config, @except ] );

   return OK;
}

sub dump_self : method {
   my $self = shift;

   $self->dumper( $self ); $self->dumper( $self->config );

   return OK;
}

sub exit_usage {
   my ($self, $level) = @_; $self->quiet( TRUE );

   my $rv = $self->$_output_usage( $level );

   if ($level == 0) { emit "\nMethods:\n"; $self->list_methods }

   exit $rv;
}

sub exit_version {
   $_[ 0 ]->output( 'Version '.$_[ 0 ]->app_version ); exit OK;
}

sub help : method {
   my $self = shift; $self->$_output_usage( 1 ); return OK;
}

sub list_methods : method {
   my $self = shift; ensure_class_loaded 'Pod::Eventual::Simple';

   my $abstract = {}; my $max = 0; my $classes = $self->$_get_classes_and_roles;

   for my $method (@{ $_list_methods_of->( $self ) }) {
      my $mlen = length $method; $mlen > $max and $max = $mlen;

      for my $class (@{ $classes }) {
         is_member( $method, Class::Inspector->methods( $class, 'public' ) )
            or next;

         my $pod = $_get_pod_header_for_method->( $class, $method ) or next;

         (not exists $abstract->{ $method }
           or length $pod > length $abstract->{ $method })
            and $abstract->{ $method } = $pod;
      }
   }

   for my $key (sort keys %{ $abstract }) {
      my ($method, @rest) = split SPC, $abstract->{ $key };

      $key =~ s{ [_] }{-}gmx; emit( (pad $key, $max).SPC.(join SPC, @rest) );
   }

   return OK;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Class::Usul::TraitFor::Usage - Help and diagnostic information for command line programs

=head1 Synopsis

   use Moo;

   extends 'Class::Usul';
   with    'Class::Usul::TraitFor::Usage';

=head1 Description

Help and diagnostic information for command line programs

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<encoding>

Decode/encode input/output using this encoding

=item C<H help_manual>

Print long help text extracted from this POD

=item C<h help_options>

Print short help text extracted from this POD

=item C<? help_usage>

Print option usage

=item C<V show_version>

Prints the programs version number and exits

=back

Requires the following;

=over 3

=item C<config>

=item C<dumper>

=item C<next_argv>

=item C<options_usage>

=item C<output>

=item C<quiet>

=back

=head1 Subroutines/Methods

=head2 dump_config_attr - Dumps the configuration attributes and values

Visits the configuration object, forcing evaluation of the lazy, and printing
out the attributes and values

=head2 dump_self - Dumps the program object

Dumps out the self referential object using L<Data::Printer>

=head2 help - Display help text about a method

Searches the programs classes and roles to find the method implementation.
Displays help text from the POD that describes the method

=head2 list_methods - Lists available command line methods

Lists the methods (marked by the I<method> subroutine attribute) that can
be called via the L<run method|Class::Usul::TraitFor::RunningMethods/run>

=head2 app_version

   $version_object = $self->app_version;

The version number of the configured application class

=head2 BUILD

Called just after the object is constructed this method handles dispatching
to the help methods

=head2 can_call

   $bool = $self->can_call( $method );

Returns true if C<$self> has a method given by C<$method> that has defined
the I<method> method attribute

=head2 exit_usage

   $self->exit_usage( $verbosity );

Print out usage information from POD. The C<$verbosity> is; 0, 1 or 2

=head2 exit_version

   $self->exit_version;

Prints out the version of the C::U::Programs subclass and the exits

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<attributes>

=item L<Class::Inspector>

=item L<Class::Usul::IPC>

=item L<Class::Usul::File>

=item L<Class::Usul::Options>

=item L<Moo::Role>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Usul.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2018 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
