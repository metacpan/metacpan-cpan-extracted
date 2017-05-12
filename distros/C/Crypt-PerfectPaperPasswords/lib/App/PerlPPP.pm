package App::PerlPPP;

use strict;
use warnings;
use Carp;
use Getopt::Long;
use Crypt::PerfectPaperPasswords;
use Pod::Usage;

=head1 NAME

App::PerlPPP - Command line tool for Perfect Paper Passwords

=head1 VERSION

This document describes App::PerlPPP version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use App::PerlPPP;

    my $app = App::PerlPPP->new;
    $app->parse_args(@ARGV);
    $app->run;

=head1 DESCRIPTION

=head1 INTERFACE 

=head2 C<< new >>

=cut

{
  my %ARG_SPEC;

  BEGIN {

    sub _range_spec {
      my ( $name, $default, $min, $max ) = @_;
      return [
        $default,
        sub {
          my ( $self, $value ) = @_;
          die "$name must be between $min and $max\n"
           if $value < $min || $value > $max;
          return $value;
         }
      ];
    }

    sub _array_spec {
      return [
        [],
        sub {
          my $self = shift;
          return [ map { 'ARRAY' eq ref $_ ? @$_ : $_ } @_ ];
        },
      ];
    }

    %ARG_SPEC = (
      show_man   => [0],
      show_help  => [0],
      args       => _array_spec(),
      columns    => _range_spec( 'columns', 7, 1, 100 ),
      rows       => _range_spec( 'rows', 10, 1, 100 ),
      codelen    => [undef],
      passphrase => [undef],
      alphabet   => [undef],
      key        => [
        undef,
        sub {
          my ( $self, $key ) = @_;
          die "Key must be 64 characters long\n"
           unless length( $key ) == 64;
          die "Key must be hexadecimal (0-9, A-F)\n"
           unless $key =~ /^[0-9A-F]{64}$/i;
          return $key;
        },
      ],
      title => ['Perfect Paper Passwords'],
    );

    while ( my ( $name, $spec ) = each %ARG_SPEC ) {
      no strict 'refs';
      my $validator = $spec->[1] || sub { shift; shift };
      *{ __PACKAGE__ . '::' . $name } = sub {
        my $self = shift;
        $self->{$name} = $self->$validator( @_ )
         if ( @_ );
        my $value = $self->{$name};
        return ( wantarray && 'ARRAY' eq ref $value )
         ? @$value
         : $value;
      };
    }
  }

  sub new {
    my ( $class, %args ) = @_;

    my $self = bless {}, $class;

    while ( my ( $name, $spec ) = each %ARG_SPEC ) {
      my $value
       = exists $args{$name} ? delete $args{$name} : $spec->[0];
      $self->$name( $value )
       if defined $value;
    }

    croak "Unknown options: ", join( ', ', sort keys %args )
     if keys %args;

    return $self;
  }
}

=head2 C<< args >>

=head2 C<< alphabet >>

=head2 C<< codelen >>

=head2 C<< columns >>

=head2 C<< rows >>

=head2 C<< key >>

=head2 C<< passphrase >>

=head2 C<< title >>

=head2 C<< show_help >>

=head2 C<< show_man >>

=head2 C<< parse_args >>

=cut

sub parse_args {
  my ( $self, @args ) = @_;

  local @ARGV = @args;

  my %options;

  GetOptions(
    'help|?'       => \$options{show_help},
    man            => \$options{show_man},
    'key=s'        => \$options{key},
    'passphrase=s' => \$options{passphrase},
    'columns=i'    => \$options{columns},
    'rows=i'       => \$options{rows},
    'title=s'      => \$options{title},
    'alphabet=s'   => \$options{alphabet},
    'codelen=i'    => \$options{codelen},
  ) or pod2usage();

  while ( my ( $name, $value ) = each %options ) {
    $self->$name( $value ) if defined $value;
  }

  $self->args( @ARGV );
}

=head2 C<< run >>

=cut

sub run {
  my $self = shift;

  if ( $self->show_help ) {
    $self->do_help;
  }
  elsif ( $self->show_man ) {
    pod2usage( -verbose => 2, -exitstatus => 0 );
  }
  else {
    my @args = $self->args;
    pod2usage() unless @args;
    my $verb = shift @args;
    if ( my $code = $self->can( "do_$verb" ) ) {
      $self->$code( @args );
    }
    else {
      die "Unknown action: $verb\n";
    }
  }
}

=head1 ACTIONS

=head2 C<< do_card >>

Output a card

=cut

sub do_card {
  my ( $self, @args ) = @_;
  my $card_no = @args ? shift @args : 1;
  die "Card numbers start at 1\n" if $card_no < 1;

  my $title = $self->title;
  my $rows  = $self->rows;
  my $cols  = $self->columns;
  my $ppp   = $self->_make_ppp;
  my @passcodes
   = $ppp->passcodes( $card_no, $rows * $cols, $self->_get_key );

  my $colw   = length( $passcodes[0] );
  my $center = sub {
    my $str = shift;
    my $pad = $colw - length $str;
    return $str if $pad <= 0;
    return ( ' ' x ( $pad / 2 ) ) . $str
     . ( ' ' x ( ( $pad + 1 ) / 2 ) );
  };

  my $row_fmt = "%4d";
  my @hdr     = ( ' ' x ( length sprintf( $row_fmt, 1 ) ) );
  my $col     = 'A';
  push @hdr, $center->( $col++ ) for ( 1 .. $cols );
  my $hdr = join( ' ', @hdr );
  my $rule = '=' x length $hdr;
  print "$title [$card_no]\n$rule\n$hdr\n$rule\n";
  for ( 1 .. $rows ) {
    print join( ' ',
      sprintf( $row_fmt, $_ ),
      splice( @passcodes, 0, $cols ) ),
     "\n";
  }
  print "$rule\n";
}

=head2 C<do_newkey>

Create and display a new random key.

=cut

sub do_newkey {
  my $self = shift;
  if ( my $key = $self->_make_key ) {
    print "Specified key is $key\n";
  }
  else {
    print "Generated key is ",
     $self->key( $self->_make_ppp->random_sequence ), "\n";
  }
}

=head2 C<do_help>

Output help page

=cut

sub do_help {
  my $self = shift;
  pod2usage( -verbose => 1 );
}

sub _make_key {
  my $self = shift;

  if ( defined( my $key = $self->key ) ) {
    return $key;
  }
  elsif ( defined( my $phrase = $self->passphrase ) ) {
    return $self->key( $self->_make_ppp->sequence_from_key( $phrase ) );
  }
  else {
    return;
  }
}

sub _get_key {
  my $self = shift;
  return $self->_make_key
   || die "Must supply --key or --passphrase\n";
}

sub _make_ppp {
  my $self = shift;
  my %args;
  for my $a ( qw( alphabet codelen ) ) {
    if ( defined( my $value = $self->$a() ) ) {
      $args{$a} = $value;
    }
  }

  return $self->{_ppp} ||= Crypt::PerfectPaperPasswords->new( %args );
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
App::PerlPPP requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Crypt::PerfectPaperPasswords>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-crypt-perfectpaperpasswords@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

Original Perfect Paper Passwords implementation by Steve Gibson. More details
here:

    http://www.grc.com/ppp.htm

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
