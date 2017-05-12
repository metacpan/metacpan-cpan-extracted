package Auth::Kokolores::Plugin::FileRetrieve;

use Moose;
use DBI;

# ABSTRACT: kokolores plugin for retrieving users from a file
our $VERSION = '1.01'; # VERSION

extends 'Auth::Kokolores::Plugin';


has 'seperator' => ( is => 'ro', isa => 'Str', default => '\s+' );
has sep_regex => (
  is => 'ro', isa => 'RegexpRef', lazy => 1,
  default => sub {
    my $self = shift;
    my $str = $self->seperator;
    my $regex = eval { qr/$str/ };
    if( $@ ) { die("invalid regex in seperator: $@") }
    return $regex;
  },
);

has 'fields' => ( is => 'ro', isa => 'Str', default => 'username,password');
has '_fields' => (
  is => 'ro', isa => 'ArrayRef[Str]', lazy => 1,
  default => sub { [ split(/\s*,\s*/, shift->fields ) ] },
  traits => [ 'Array' ],
  handles => { 
    'num_fields' => 'count',
  }
);

has 'file' => ( is => 'ro', isa => 'Str', required => 1 );

has 'fh' => (
  is => 'ro', isa => 'IO::File', lazy => 1,
  default => sub {
    my $self = shift;
    my $fh = IO::File->new( $self->file, 'r',);
    if( ! defined $fh ) {
      die("could not open user file: $!");
    }
    return $fh;
  },
);

has 'comments' => ( is => 'ro', isa => 'Bool', default => 0 );

sub parse_line {
  my ( $self, $line, $ln ) = @_;
  my $data = {};
  if( $self->comments && $line =~ /^\s*#/ ) {
    return;
  }
  $line =~ s/[\r\n]*$//;
  my $sep = $self->sep_regex;
  my @values = split( $sep, $line );
  if( scalar @values < $self->num_fields ) {
    $self->server->log(2, "insufficient fields on line $ln");
    return;
  }
  foreach my $fieldname ( @{$self->_fields} ) {
    $data->{$fieldname} = shift( @values );
  }
  return $data;
}

has 'username_field' => ( is => 'rw', isa => 'Str', default => 'username' );

sub lookup_user {
  my ( $self, $key ) = @_;
  my $username_field = $self->username_field;
  my $ln = 0;
  $self->fh->setpos(0);
  while( my $line = $self->fh->getline ) {
    $ln++;
    my $user = $self->parse_line( $line, $ln );
    if( defined $user->{$username_field}
        && $user->{$username_field} eq $key) {
      $self->log(4, "found user on line $ln" );
      return $user;
    }
  }
  return;
}

sub authenticate {
  my ( $self, $r ) = @_;
  
  $self->log(4, "searching for user ".$r->username );
  my $user = $self->lookup_user( $r->username );
  if( ! defined $user ) {
    $r->log(3, 'could not find user '.$r->username);
    return 0;
  }

  foreach my $field ( keys %$user ) {
    if( ! defined $user->{$field} ) {
      next;
    }
    $r->log(4, 'retrieved userinfo '.$field.'='.$user->{$field});
    $r->set_info( $field, $user->{$field} );
  }

  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Plugin::FileRetrieve - kokolores plugin for retrieving users from a file

=head1 VERSION

version 1.01

=head1 DESCRIPTION

Retrieve a user from a line based password file.

Will fail if no user is found.

=head1 EXAMPLE

  <Plugin retrieve-user>
    module = "FileRetrieve"
    file = "users.txt"
    seperator = "\s+"
    fields = "username,password"
  </Plugin>

=head1 MODULE PARAMETERS

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
