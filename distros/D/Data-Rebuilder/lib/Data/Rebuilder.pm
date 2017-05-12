
use strict;
use warnings;
package Data::Rebuilder;

=head1 NAME

Data::Rebuilder - Builds an object rebuilder.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  ###
  ### freeze composite ...
  ###
  
  my $builder = Data::Rebuilder->new;
  $builder->parameterize( driver => $driver );
  $builder->parameterize( user   => $user );
  my $icy_compsite = $builder->build_rebulder( $composite );
  
  ###
  ### restore composite with current context ...
  ###
  
  my $builder = eval $icy_composite;
  my $melted_composite = $builder->( driver => $driver,
                                     user   => $user );

=head1 DESCRIPTION

This approach is like to C<Data::Dumper> approach. Moreover,
an output of this module is not easy to read.

However this solution can rebuild tied values, weak references, 
and closures.
In addition, this solution can parameterize 
arbitrary nodes of composite. Users can give new objects as 
arguments of the subroutine which is result.

=cut

use B;
use Scalar::Util qw( isweak refaddr blessed looks_like_number);
use UNIVERSAL qw(isa  can);
use Carp;
use Sub::Name;
use Path::Class;
use Lexical::Alias;
use B::Deparse;
use PadWalker;
use Data::Polymorph;


=head1 STATIC METHODS

=over 4

=item safe_require

  safe_require ( $0 );                                # does not load
  safe_require ( Path::Class::file( $0 )->absolute ); # does not load
  safe_require ( 'path/to/module.pm' );               # loads
  safe_require ( '/absolute/path/to/module.pm');      # does not load

Loads module safery.

=cut


{
  my %loaded = ();
  sub safe_require ($){
    my $lib = shift;
    my $libabs = file($lib)->absolute;
    return if $loaded{$libabs};
    return if $libabs eq file($0)->absolute;
    $loaded{$libabs} = 1;
    require $lib unless grep{ $libabs eq file($_)->absolute } values %INC;
  }
}

sub _indent ($) {
  local $_ = shift;
  s/\n/\n  /mg;
  $_;
}

{ ############################################################
  package Data::Rebuilder::B::Deparse;
  our @ISA = qw( B::Deparse );

  sub coderef2textX{
    my $self = shift;
    my $code = $self->coderef2text( @_ );
    (
     globals => [ keys %{$self->{' globals '}} ],
     stashes => [ keys %{$self->{' stashes '}} ],
     code    => $code
    );
  }

  {
    my %globalnames =
      map (($_ => 1), qw(SIG STDIN STDOUT STDERR INC ENV ARGV ARGVOUT _));

    sub gv_name {
      my $self = shift;
      my $gv = shift;
      Carp::confess() unless ref($gv) eq "B::GV";
      my $stash = $gv->STASH->NAME;
      $self->{' stashes '}->{$stash} = 1;
      my $name = $gv->SAFENAME;
      if ($stash eq 'main' && $name =~ /^::/) {
	$stash = '::';
      }
      elsif (($stash eq 'main' && $globalnames{$name})
#              or ($stash eq $self->{'curstash'} && !$globalnames{$name}
#                  && ($stash eq 'main' || $name !~ /::/))
#              or $name =~ /^[^A-Za-z_:]/
            )
        {
          $stash = "";
        } else {
          $stash = $stash . "::";
        }
      if ($name =~ /^(\^..|{)/) {
        $name = "{$name}";       # ${^WARNING_BITS}, etc and ${
      }
      return $stash . $name;
    }

    sub stash_variable{
      my $self = shift;
      my $ret = $self->SUPER::stash_variable(@_);
      my $name = $ret;
      $name =~ s/^\W//;
      $self->{' globals '}->{$ret} = 1 unless $globalnames{$name};
      $ret;
    }
  }
} ############################################################


{
  my @template =
    ([poly => sub{
        my ($self) = @_;
        my $poly = Data::Polymorph->new;
        my %blank =
          (
           Undef     => sub{ 'do{my $a;\$a}' },
           HashRef   => sub{ "{}" },
           ArrayRef  => sub{ "[]" },
           ScalarRef => sub{ 'do{my $a;\$a}' },
           GlobRef   => sub{ $self->poly->apply($_[0] => 'freeze') },
           Glob      => sub{ $self->poly->apply($_[0] => 'freeze') },
           Str       => sub{ $_[0]. "" },
           Num       => sub{ $_[0]. "" },
          );

        my %tier =
          (
           HashRef   => sub{
             my ( $obj, $objexpr ) = @_;
             (sprintf('%%{%s}',  $objexpr), "TIEHASH")
           },

           ArrayRef  => sub{
             my ( $obj, $objexpr ) = @_;
             (sprintf('@{%s}', $objexpr), "TIEARRAY")
           },

           ScalarRef => sub{
             my ( $obj, $objexpr ) = @_;
             (sprintf('${%s}', $objexpr),"TIESCALAR")
           },

           GlobRef   => sub{
             my ( $obj, $objexpr ) = @_;
             (sprintf('*{%s}', $objexpr),"TIEHANDLE")
           },

           Glob      => sub{
             my ( $obj, $objexpr ) = @_;
             (sprintf('*{%s}', $objexpr),"TIEHANDLE");
           },

           Str       => sub{
             my ( $obj, $objexpr ) = @_;
             ( $objexpr , "TIESCALAR" );
           },

           Num       => sub{
             my ( $obj, $objexpr ) = @_;
             ( $objexpr , "TIESCALAR" );
           },

          );

        my %tied =
          (
           HashRef   => sub{ tied %{$_[0]} },
           ArrayRef  => sub{ tied @{$_[0]} },
           ScalarRef => sub{ tied ${$_[0]} },
           GlobRef   => sub{ tied *{$_[0]} },
           Glob      => sub{ tied *{$_[0]} },
           Str       => sub{ tied $_[0]    },
           Num       => sub{ tied $_[0]    },
           Any       => sub{ undef },
          );

        my %module_loader =
          (
           Any       =>  sub{()},

           UNIVERSAL =>  sub{
             my $obj = shift;
             my $class = blessed $obj || $obj;
             my $pm = $class;
             $pm =~ s#::#/#g;
             $pm =~ s#$#.pm#;
             return "require $class;" if exists $INC{$pm};

             my $stashglob = do{no strict 'refs'; *{"${class}::"}};
             my %stash = %{$stashglob};
             my %files;
             foreach my $glob ( values %stash ) {
               my $code = *{$glob}{CODE};
               next unless $code;
               my $b = B::svref_2object($code);
               next if $b->XSUB;
               my $file = $b->FILE;
               $files{$file} = 1;
             }
             map( sprintf( '%s::safe_require %s;',
                           __PACKAGE__,
                           $self->freeze(file($_)->absolute->stringify)),
                  keys %files );
           },

           Regexp => sub{
             ( exists( $INC{'Regexp.pm'} )
               ? ("require Regexp;")
               : () )
           },
          );


        my %freezer =
          (
           ###
           Any   => sub{ confess "caught unsupported type." },

           ###
           Undef => sub{ 'undef' },

           ###
           'Str' => sub{ B::perlstring( $_[0] ) },

           ###
           'Num' => sub{ $_[0] },

           ###
           'Glob' => sub{
             my $obj  = shift;
             my $name = "" . $obj;
             return "$name" unless $name =~ /^\*Symbol::GEN/;
             join("\n",
                  'do{',
                  '  # GrobRef',
                  '  require Symbol;',
                  '  my $__tmp = Symbol::gensym();',
                  ( map {
                    ( *{$obj}{$_}
                      ? ( sprintf('  *{$__tmp} = %s;',
                                  $self->freeze(*{$obj}{$_})) )
                      : () )
                    } qw( SCALAR
                          ARRAY
                          HASH
                          CODE )),
                  '  *$__tmp;',
                  '}' );
           },

           ###
           'ScalarRef' => sub{
             my $obj = shift;
             join( "\n",
                   'do{',
                   '  #ScalarRef',
                   '  my $__tmp = '.$self->freeze($$obj).';',
                   '  \\$__tmp;',
                   '}' );
           },

           #################################
           'CodeRef' => sub{
             my $cv     = shift;
             my $target = shift || $cv;
             my $var    = $self->ref_to_var($target);

             my $dp     =  ( $self->{_deparse}
                             ||= (__PACKAGE__."::B::Deparse")->new );
             my $closed = PadWalker::closed_over( $cv );
             my $b      = B::svref_2object($cv);
             my $name   = $b->GV->NAME;
             my @vars   = ();

             foreach my $key (keys %$closed) {

               my $val = $closed->{$key};

               if( $self->poly->type($val) eq 'RefRef' &&
                   $self->_is_cycled($$val)) {
                 push @vars,
                   sprintf('  my %s = undef; #cycled RefRef', $key);
                 my $lazy = $self->_lazy->{refaddr $$val} ||= [];

                 push
                   (@$lazy,
                    'require PadWalker;',
                    sprintf('${PadWalker::closed_over(%s)->{%s}} = %s;',
                            $var,
                            $self->freeze($key),
                            $self->freeze($$val))
                    );
               }
               else {
                 push( @vars,
                       sprintf ( "  my \%s = undef;\n".
                                 '  Lexical::Alias::alias_r( %s , \%s );',
                                 $key,
                                 $self->freeze($val),
                                 $key ) );
               }

             }

             my %info = $dp->coderef2textX($cv);

             foreach my $stash ( $b->STASH->NAME , @{$info{stashes}} ){
               $self->_stashes->{$stash} = 1;
             }

             join( "\n",
                   "do{",
                   '  # CodeRef',
                   (map{ sprintf('  %s = %s;',$_,$_) }@{$info{globals}}),
                   ( @vars ? '  require Lexical::Alias;' : () ),
                   @vars,
                   sprintf('  sub %s', _indent $info{code}),
                   "}",
                 );
           },

           #################################
           'ArrayRef' => sub{

             my $ref    = shift;
             my $target = shift || $ref;
             my $var    = $self->ref_to_var($target);

             my @body = ();
             my @tied = ();
             my @weak = ();
             local $_;

             for( my $i = 0; $i < @{$ref} ; $i++ ) {
               my $v = $ref->[$i];
               my $tied = tied ( $ref->[$i] );
               push @body, sprintf('    # %s', refaddr( \$ref->[$i] ));
               if( $tied ){

                 push @body, "    undef,";
                 push @tied , [$i => $tied];

               }
               elsif( $self->_is_cycled($v) ) {

                 push @body, "    undef,";
                 my $lazy = $self->_lazy->{ refaddr $v } ||= [];
                 push( @$lazy ,
                       sprintf('%s->[%s] = %s;',
                               $var, $i, $self->freeze($v)));
                 push( @$lazy ,
                       sprintf('Scalar::Util::weaken(%s->[%s]);',
                               $var, $i))
                   if isweak($ref->[$i]);

               }
               elsif( $self->poly->type($v) eq 'RefRef'  and
                      $self->_is_cycled($$v)){
                 push @body, "    undef, #cycled RefRef ";
                 my $lazy = $self->_lazy->{refaddr $$v} ||= [];
                 push @{$lazy}, sprintf('%s->[%s] = %s;',
                                        $var,
                                        $i,
                                        $self->poly->apply( $v => 'freeze'));
                 push( @$lazy ,
                       sprintf('Scalar::Util::weaken(%s->[%s]);',
                               $var, $i))
                   if isweak($ref->[$i]);
               }
               else {

                 push @body , "    ". $self->freeze($v).",";
                 push @weak , $i , if isweak( $ref->[$i] );

               }
             }

             join
               (
                "\n" ,
                "do{ ",
                '  # ArrayRef',
                "  my \$__tmp = [",
                @body ,
                "  ];",
                "  "._indent( join "\n",
                              map{ $self->tier('$__tmp->['.$_->[0].']',
                                               'TIESCALAR',
                                               $_->[1]) } @tied ),
                "  "._indent( join "\n",
                              map{ sprintf(' Scalar::Util::weaken('.
                                           '  $__tmp->[%s] );' ,
                                           $_) } @weak ),
                '  $__tmp;',
                "}"
               );
           },

           #################################
           'HashRef' => sub{
             my $ref    = shift;
             my $target = shift || $ref;
             my $var    = $self->ref_to_var($target);
             my @body = ();
             my @tied = ();
             my @weak = ();

             foreach my $key ( sort keys %{$ref} ){
               my $v = $ref->{$key};
               my $tied = tied ( $ref->{$key} );
               if( $tied ){
                 push @body ,
                   sprintf('      %s => undef,',  $self->freeze($key)),
                 push @tied , [$key => $tied];
               }
               elsif( $self->_is_cycled($v) ) {

                 push @body ,
                   sprintf('      %s => undef, # cycled', $self->freeze($key));

                 my $lazy = $self->_lazy->{ refaddr $v } ||= [];

                 push( @$lazy , sprintf('%s->{%s} = %s;',
                                         $var,
                                         $self->freeze($key),
                                         $self->freeze($v)));

                 push( @$lazy ,
                       sprintf('Scalar::Util::weaken(%s->{%s});',
                               $var,
                               $self->freeze($key)
                              )) if isweak($ref->{$key});

               }
               elsif( $self->poly->type($v) eq 'RefRef'  and
                      $self->_is_cycled($$v)){

                 push @body, sprintf('      %s => undef, # cycled RefRef',
                                    $self->freeze($key));

                 my $lazy = $self->_lazy->{refaddr $$v} ||= [];

                 push @{$lazy}, sprintf('%s->{%s} = %s;',
                                        $var,
                                        $self->freeze($key),
                                        $self->freeze($v));

                 push( @$lazy ,
                       sprintf('Scalar::Util::weaken(%s->{%s});',
                               $var,
                               $self->freeze($key),
                              )) if isweak($ref->{$key});

               }
               else {
                 push @body ,
                   sprintf('      %s => %s,',
                           $self->freeze($key), $self->freeze($v));
                 push @weak , $key, if isweak( $ref->{$key} );
               }
             }

             join
               (
                "\n" ,
                "do{ ",
                '  # HashRef',
                "  my \$__tmp = {",
                @body ,
                "  };",
                ( map{ $self->tier('$__tmp->{'.$self->freeze($_->[0]).'}',
                                   'TIESCALAR',
                                   $_->[1]) } @tied ),
                ( map{ sprintf(' Scalar::Util::weaken( \ $__tmp->{%s} );' ,
                               $self->freeze($_)) }
                  @weak ),
                '  $__tmp;',
                "}"
               );
           },

           #################################
           'GlobRef' => sub{
             my $glob   = shift;
             my $target = shift;
             my $var    = $self->ref_to_var($target);
             my $name = "".$$glob;

             return '\\ '.$name
               if( $name =~ /\*main::(STD(?:IN|OUT|ERR)|ARGV)/ &&
                   refaddr( $glob ) == refaddr( \$main::{$1} ) );

             my @slots = ();
             foreach my $slot ( qw(SCALAR HASH ARRAY CODE)) {

               next unless my $ref = *{$glob}{$slot};

               if( $self->poly->type($slot) eq 'RefRef' &&
                   $self->_is_cycled($$slot) ) {
                 my $lazy = ($self->_lazy->{refaddr $$slot} ||= []);
                 push @$lazy,
                   sprintf('  *{%s} = %s;',
                           $var,
                           $self->freeze(*{$glob}{$slot}) );
               }
               else {
                 push @slots,
                   sprintf('  *{$__tmp} = %s;',
                           $self->freeze(*{$glob}{$slot}) );
               }

             }
             join ("\n",
                   'do {',
                   '  require Symbol;',
                   sprintf('  my $__tmp = Symbol::gensym();', $name),
                   @slots,
                   '  $__tmp;',
                   '}',
                  );
           },

           ###
           'RefRef' => sub{
             my $ref    = shift;
             my $target = shift || $ref;
             "\\ ". $self->freeze( ${$ref} , ${$target} );
           },

           ###
           UNIVERSAL => sub {
             my $obj    = shift;
             my $target = shift || $obj;
             $self->_stashes->{blessed $obj} = 1;
             join
               (
                "\n",
                'do{',
                sprintf("  bless(\%s,\n  \%s)",
                        _indent( $poly->super($obj => 'freeze' , $target) ),
                        $self->freeze(blessed $obj)),
                '}'
                );
           },

           ###
           Regexp => sub {
             my $obj    = shift;
             my $target = shift || $obj;
             join( "\n",
                   "do{",
                   "  ". _indent( $self->module_loader('Regexp') ),
                   sprintf('my $__tmp = %s ;', $self->freeze("". $obj)),
                   "}");
           },
          );

        my %pre_freeze =
          (
           Any  => sub{
             ()
           },

           Ref     => sub{
             my $ref = shift;
             my $target = shift || $ref;
             $self->_dumped->{ refaddr $target } = $self->ref_to_var($target);
             ()
           },

           ArrayRef => sub{
             my $ref    = shift;
             my $target = shift || $ref;
             my $var    = $self->ref_to_var($target);
             $self->poly->super($ref => 'pre_freeze' , $target);
             for( my $i = 0; $i < @$ref; $i++ ) {
               $self->_dumped->{ refaddr( \ $ref->[$i] ) } =
                 sprintf('\ %s->[%s]', $var, $i);
             }
             ()
           },

           HashRef => sub{
             my $ref    = shift;
             my $target = shift || $ref;
             my $var    = $self->ref_to_var( $target );
             $self->poly->super($ref => 'pre_freeze' , $target);
             foreach my $key ( keys %$ref ) {
               $self->_dumped->{ refaddr( \ $ref->{ $key } ) } =
                 sprintf('\ %s->{%s}', $var,  $self->freeze($key));
             }
             ()
           },
          );

        my %post_freeze =
          (
           Any  => sub{ () },

           Ref  => sub{
             my $ref    = shift;
             my $target = shift || $ref;
             my $addr   = refaddr $target;
             my $lazy   = delete($self->_lazy->{$addr}) || [];
             $self->_complete->{$addr} = 1;
             @$lazy;
           },

           ArrayRef => sub{
             my $ref    = shift;
             my $target = shift || $ref;
             (
              $self->poly->super($ref => 'post_freeze', $target) ,
              map { $self->poly->apply( \$ref->[$_] => 'post_freeze') }
              ( 0 ... $#{$ref} )
             );
           },

           HashRef      => sub{
             my $ref    = shift;
             my $target = shift || $ref;
             (
              $self->poly->super($ref => 'post_freeze' , $target) ,
              ( map { $self->poly->apply( \$ref->{$_} => 'post_freeze') }
                sort keys %$ref )
             );
           },
          );

        my %sleep =
          (
           Any         => sub{ $_[0] },
           __PACKAGE__ , sub{
             my %sleepy = %{$_[0]};
             delete $sleepy{$_} foreach qw( _stashes
                                            _deparse
                                            _result
                                            _params
                                            _complete
                                            _lazy );
             bless \%sleepy, blessed $_[0];
           },
          );


        foreach ( [tied          => \%tied],
                  [tier          => \%tier],
                  [blank         => \%blank],
                  [module_loader => \%module_loader],
                  [pre_freeze    => \%pre_freeze],
                  [freeze        => \%freezer],
                  [sleep         => \%sleep],
                  [post_freeze   => \%post_freeze]) {
          my ( $meth, $dic ) = @$_;
          while( my ($class, $sub) = each %{$dic} ) {
            $poly->define( $class => $meth =>
                           ( subname "$class->$meth" => $sub ) );
          }
        }

        $poly;
      }],

     [_stashes  => sub{ {}    }],
     [_deparse  => sub{ undef }],
     [_result   => sub{ []    }],
     [_params   => sub{ {}    }],
     [_dumped   => sub{ {}    }],
     [_complete => sub{ {}    }],
     [_lazy     => sub{ {}    }],
    );

  sub{
    my $caller = caller;
    foreach ( @_ ) {
      my $name = $_;
      my $glob = do{no strict 'refs'; \*{"${caller}::$name"}};
      *{$glob} = sub ($;$){
        my $self = shift;
        return $self->{$name} unless @_;
        $self->{$name} = shift;
      };
    }
  }->( map { $_->[0]} @template );

=item C<new>

  my $builder = Data::Rebuilder->new;

Creates and returns new object.
It does not receives any arguments.

=back

=head1 ATTRIBUTES

=over 4

=item C<poly>

Contains C<Data::Polymorph> instance.

=back

=cut

  sub new {
    my ($self) = @_;
    $self = bless {},( blessed $self ) || $self;
    foreach my $slot ( @template ) {
      $self->{$slot->[0]} = $slot->[1]->($self);
    }
    $self;
  }

}


=head1 DYNAMIC METHODS

=over 4

=item C<ref_to_var>

  my $var = $builder->ref_to_var( $ref ); # returns $__17898432__

Makes a reference to a variable name.

=cut

sub ref_to_var{ sprintf( '$__%d__', refaddr( $_[1] ) || '') }

sub _is_cycled {
  my ( $self, $v ) = @_;
  return 0 unless ref $v;
  my $addr = refaddr $v;
  return 0 if $self->_complete->{ $addr };
  exists $self->_dumped->{ $addr };
}

=item C<parameterize>

  $builder->parameterize( a_object => $a_object );

Register an object as a parameter of rebuilders.

=cut

sub parameterize {
  my ( $self, $key, $rv ) = @_;
  $self->_params->{ $key } = $rv;
}

=item C<register_freezer>

  $builder->register_freezer( 'Target::Class' => sub{ ... } );

same as

  $builder->poly->define( 'Target::Class' => freeze => sub{ ... }  );

Registers freezer method for the types (or classes).

Customization of this approach is not easy way. As other way, you can customize
by C<register_sleep> and C<register_module_loader>.

=cut

sub register_freezer {
  my ($self, $class, $code) = @_;
  $self->poly->define( $class => freeze => $code );
}

=item C<register_sleep>

  $builder->register_sleep( 'Target::Class' => sub{
    my $self = shift;
    return ( { foo  => $self->foo,
               bar  => $self->bar,
               bazz => $self->bazz } , sub{
      my $obj = shift;
      bless $obj , blessed $self;
      $obj->init;
      $obj;
    } )
  } );

Registers "sleep" method for the class.

You can drop some properties that is not necessary
for the serialization by these methods.

The "sleep" method returns an object and an optional subroutine reference.
They are a information for serializer and a restructuring procedure for 
the information.
So , when rebuilding the object , a rebuilder uses these informations.

=cut

sub register_sleep {
  my ($self, $class, $code) = @_;
  $self->poly->define( $class => sleep => $code );
}

=item C<register_module_loader>

  $builder->register_module_loader( 'Foo::Class' => sub{ 'require Foo;' }  );

Registers a module loader builder.
The default method of this searches files from any CVs 
in the symbol table of the class, and builds loading code 
with these information.

=cut

sub register_module_loader {
  my ($self, $class, $code) = @_;
  $self->poly->define( $class => module_loader => $code );
}

=item C<module_loader>

  # returns 'require Symbol;'
  $exp = $dumper->module_loader('Symbol');
  
  # returns 'B::Rebuilder::safe_require "/path/to/your/UNIVERSAL.pm"'
  $exp = $dumper->module_loader('UNIVERSAL');

Returns an expression which reads module for the given package name.

=cut

sub module_loader {
  my ($self, $class) = @_;
  my $meth = $self->poly->class_method( $class, 'module_loader' );
  join("\n", $meth ? $meth->($class) : ());
}

=item C<blank>

  $exp = $dumper->blank( { foo => 'bar' } ); # returns '{}'
  $exp = $dumper->blank( [ foo => 'bar' ] ); # returns '[]'
  $exp = $dumper->blank( FileHandle->new  ); # returns 'Symbol::gensym()'

A return value of this method is for tiers.

=cut

sub blank {
  my ( $self, $val ) = @_;
  $self->poly->apply( $val => 'blank' );
}

=item C<tier>

  $exp = $builder->tier( '$foo', 'TIEHANDLE', $obj );

Returns a expression which ties variable with the tied object.

=cut

sub tier {
  my ( $self , $varexpr, $tier, $tied ) = @_;
  my $pkg = blessed $tied;
  join ("\n",
        sprintf('do{'),
        sprintf('  no warnings;'),
        sprintf('  my %%old = ();'),
        sprintf('  foreach my $s (qw(SCALAR ARRAY HASH CODE)){'),
        sprintf('     $old{$s} = *%s::%s{$s};', $pkg , $tier),
        sprintf('  }'),
        sprintf('  *%s::%s = sub{ %s }; ', $pkg, $tier, $self->freeze($tied)),
        sprintf('  tie %s , %s;' , $varexpr, $self->freeze($pkg)),
        sprintf('  delete $%s::{%s};', $pkg, $tier),
        sprintf('  foreach my $s (qw(SCALAR ARRAY HASH CODE)){'),
        sprintf('     *%s::%s = $old{$s} if defined $old{$s};', $pkg, $tier),
        sprintf('  }'),
        sprintf('};'),
       );
}

=item C<freeze>

  my $icy = $dumper->freeze( $obj );

Makes Perl source code which builds given object.
This method should not be used from applications, because 
it modifies the objects state. This method should be used from extensions.

=cut

sub freeze {

  my ( $self, $val ) = @_;

  return $self->poly->apply( $val => freeze => ) unless ref $val;

  my $addr = refaddr( $val );

  return $self->_dumped->{ $addr } if exists $self->_dumped->{ $addr };

  my ($sleep, $rebuilder) = $self->poly->apply( $val => 'sleep' );

  my $var  = $self->ref_to_var( $val );

  $self->poly->apply( $sleep => 'pre_freeze' => $val );

  if( my $tied = $self->poly->apply( $val => 'tied' ) ){

    my $var = $self->ref_to_var( $val );

    push @{$self->_result},
      join("\n",
         sprintf('my %s = %s;', $var,  $self->blank($val)),
         $self->tier( $self->poly->apply( $val => 'tier', $var ),  $tied ));

  }
  elsif( $self->poly->type($sleep) eq 'RefRef'  and
         $self->_is_cycled($$sleep)){

    my $lazy = $self->_lazy->{refaddr $$sleep} ||= [];
    push @{$lazy}, sprintf('%s = %s;',
                           $var, $self->poly->apply( $sleep  => 'freeze' ,
                                                     $val ));
    push @{$self->_result}, sprintf('my %s = undef;', $var);
  }
  else {
    push @{$self->_result},
      sprintf( 'my %s = %s;',
               $self->ref_to_var( $val ) ,
               _indent( $self->poly->apply( $sleep  => 'freeze', $val ) ));
  }

  push @{$self->_result}, $self->poly->apply( $sleep => 'post_freeze', $val );
  push ( @{$self->_result},
         sprintf('%s->(%s);',  $self->freeze($rebuilder), $var) )
    if $rebuilder;

  $var;

}

=item C<rebuilder>

  my $icy = $dumper->build_rebulder( $obj );

Builds Perl source code which is object rebuilder subroutine.

=cut

sub rebuilder {

  my ($self, $rv) = @_;
  return sprintf('sub{%s}', $self->freeze($rv))  unless ref $rv;
  my @checker   = ();
  my @result    = ();
  my $_complete = {};
  my $_dumped   = {};
  my $_params   = $self->_params;

  foreach my $key (keys %$_params) {
    my $dkey = $self->freeze($key);
    my $slot = sprintf('$__ARGS__{%s}', $dkey);
    my $addr = refaddr($_params->{$key});
    $_dumped->{ $addr }   = $slot;
    $_complete->{ $addr } = 1;
    push (
          @result ,
          sprintf( 'my %s = %s;',
                   $self->ref_to_var($_params->{$key}),
                   $slot )
         );
    push ( @checker ,

           sprintf('Carp::confess %s." is not specified"'."\n".
                   '    unless exists %s;',
                   $dkey, $slot),

           sprintf('Carp::confess %s." is not a reference"'."\n".
                   '    unless ref %s;',
                   $dkey, $slot) );
  }

  $self->_stashes({});
  $self->_dumped( $_dumped );
  $self->_result( \@result );
  $self->_complete( $_complete  );
  $self->_lazy( {} );

  my $var = $self->freeze($rv);

  return join (
               "\n",
               'do{ ',
               '  require '.__PACKAGE__.';',
               ( map{
                 "  ".$self->module_loader($_)
               }(keys %{$self->_stashes})),
               '  my $RETVAL = sub (%){',
               '    require Scalar::Util; ',
               "    require Carp;",
               '    my %__ARGS__ = @_;',
               "    "._indent(_indent(join "\n",@checker)),
               "    ". _indent(_indent(join "\n", @{ $self->_result })),
               "    $var;",
               '  };',
               '  $RETVAL',
               '}'
              );
}


1; # End of Data::Rebuilder

__END__


=back


=head1 SEE ALSO

=over 4

=item C<Data::Dumper>

=back

=head1 AUTHOR

lieutar, C<< <lieutar at 1dk.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-dumper-sub at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Rebuilder>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

and...

Even if I am writing strange English because I am not good at English, 
I'll not often notice the matter. (Unfortunately, these cases aren't
testable automatically.)

If you find strange things, please tell me the matter.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Rebuilder


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Rebuilder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Rebuilder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Rebuilder>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Rebuilder>

=back


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 lieutar, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
