use 5.006;
use strict;
use warnings;

package Data::Handle;

our $VERSION = '1.000001';

# ABSTRACT: A Very simple interface to the __DATA__  file handle.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY





















































































my %datastash;
use Symbol qw( gensym );
use Scalar::Util qw( weaken );
use parent qw( IO::File );
use Package::Stash 0.15;    # has_symbol
use Carp ();
use Data::Handle::Exception;
use Data::Handle::IO;
use Try::Tiny qw( try catch );









sub new {
  my ( $class, $targetpackage ) = @_;

  _e('NoSymbol')->throw("$targetpackage has no DATA symbol")
    if ( !$class->_has_data_symbol($targetpackage) );

  if ( !$class->_is_valid_data_tell($targetpackage) ) {
    _e('BadFilePos')
      ->throw( "$targetpackage has a DATA symbol, but the filepointer"
        . " is well beyond the __DATA__ section.\n"
        . " We can't work out safely where it is.\n"
        . $class->_stringify_metadata($targetpackage)
        . "\n" );
  }

  my $sym  = gensym();
  my $xsym = $sym;
  weaken($xsym);

  ## no critic( ProhibitTies )
  tie *{$sym}, 'Data::Handle::IO', { self => $xsym };
  ${ *{$sym} }{stash} = {};
  bless $sym, $class;
  $sym->_stash->{start_offset}   = $class->_get_start_offset($targetpackage);
  $sym->_stash->{targetpackage}  = $targetpackage;
  $sym->_stash->{current_offset} = $class->_get_start_offset($targetpackage);
  $sym->_stash->{filehandle}     = $class->_get_data_symbol($targetpackage);
  return $sym;

}

sub _has_data_symbol {
  my ( undef, $package ) = @_;
  my $rval = undef;
  try {
    my $stash = Package::Stash->new($package);
    return unless $stash->has_symbol('DATA');
    my $fh = $stash->get_symbol('DATA');
    $rval = defined fileno *{$fh};
  }
  catch {
    if (/is not a module name/) {
      $rval = undef;
      return;
    }
    ## no critic (RequireCarping)
    die $_;
  };
  return $rval;
}

sub _get_data_symbol {
  my ( $self, $package ) = @_;
  if ( !$self->_has_data_symbol($package) ) {
    _e('Internal::BadGet')->throw('_get_data_symbol was called when there is no data_symbol to get');
  }
  return Package::Stash->new($package)->get_symbol('DATA');
}

sub _get_start_offset {
  my ( $self, $package ) = @_;

  return $datastash{$package}->{offset}
    if ( exists $datastash{$package}->{offset} );

  if ( !$self->_has_data_symbol($package) ) {
    _e('Internal::BadGet')->throw('_get_start_offset was called when there is no data_symbol to get');
  }
  my $fd       = $self->_get_data_symbol($package);
  my $position = tell $fd;

  $datastash{$package}->{offset} = $position;

  return $position;
}

sub _is_valid_data_tell {
  my ( $self, $package ) = @_;
  return 1
    if ( exists $datastash{$package} && 1 == $datastash{$package}->{valid} );
  if ( !$self->_has_data_symbol($package) ) {
    _e('Internal::BadGet')->throw('_is_valid_data_tell was called when there is no data_symbol to get');
  }

  my $fh     = $self->_get_data_symbol($package);
  my $offset = $self->_get_start_offset($package);

  # The offset to the start of __DATA__ is 9 bytes because it includes the
  # trailing \n
  #
  my $checkfor = qq{__DATA__\n};
  seek $fh, ( $offset - length $checkfor ), 0;
  read $fh, my ($buffer), length $checkfor;
  seek $fh, $offset, 0;

  $datastash{$package}->{previous_bytes} = $buffer;

  if ( $buffer eq $checkfor ) {
    $datastash{$package}->{valid} = 1;
    return 1;
  }
  else {
    $datastash{$package}->{valid} = 0;
    return;
  }
}

sub _stringify_metadata {
  my ( undef, $package ) = @_;
  my @lines = ();
  if ( not exists $datastash{$package} ) {
    push @lines, "Nothing known about $package\n";
    return join "\n", @lines;
  }
  else {
    push @lines, q{Offset : } . $datastash{$package}->{offset};
    push @lines, q{Prelude : '} . $datastash{$package}->{previous_bytes} . q{'};
    push @lines, q{Valid: } . $datastash{$package}->{valid};
    return join "\n", @lines;
  }
}

sub _readline {
  my ( $self, @args ) = @_;

  _e('API::Invalid::Params')->throw('_readline() takes no parameters') if @args;

  my $fh = $self->_fh;
  $self->_restore_pos();
  if (wantarray) {
    my @result = <$fh>;
    $self->_set_pos();
    return @result;
  }
  my $result = <$fh>;
  $self->_set_pos();
  return $result;
}

sub _read {
  my ( $self, undef, $len, $offset ) = @_;

  ## no critic ( ProhibitMagicNumbers )
  _e('API::Invalid::Params')->throw('_read() takes 2 or 3 parameters.')
    if ( scalar @_ < 3 or scalar @_ > 4 );

  $self->_restore_pos();
  my $return;
  if ( defined $offset ) {
    $return = read $self->_fh, $_[1], $len, $offset;
  }
  else {
    $return = read $self->_fh, $_[1], $len;
  }
  $self->_set_pos();
  return $return;
}

sub _getc {
  my ($self) = @_;
  _e('API::Invalid::Params')->throw('_get() takes 0 parameters.')
    if scalar @_ > 1;
  $self->_restore_pos();
  my $return = getc $self->_fh;
  $self->_set_pos();
  return $return;
}

sub _seek {
  my ( $self, $position, $whence ) = @_;

  ## no critic ( ProhibitMagicNumbers )

  _e('API::Invalid::Params')->throw('_seek() takes 2 params.')
    if scalar @_ != 3;

  my $fh = $self->_stash->{filehandle};

  if ( 0 == $whence ) {
    $position = $self->_stash->{start_offset} + $position;
  }
  elsif ( 1 == $whence ) {
    $whence   = 0;
    $position = $self->_stash->{current_offset} + $position;
  }
  elsif ( 2 == $whence ) {
  }
  else {
    _e('API::Invalid::Whence')->throw('Expected whence values are 0,1,2');
  }
  my $return = seek $fh, $position, $whence;
  $self->_set_pos();
  return $return;
}

sub _tell {
  my ($self) = shift;
  _e('API::Invalid::Params')->throw('_tell() takes no params.') if @_;
  return $self->_stash->{current_offset} - $self->_stash->{start_offset};
}

sub _eof {
  my $self = shift;
  _e('API::Invalid::Params')->throw("_eof() takes no params : @_ ")
    if @_ && $_[0] != 1;
  $self->_restore_pos();
  return eof $self->_stash->{filehandle};
}

sub _restore_pos {
  my $self = shift;
  return seek $self->_stash->{filehandle}, $self->_stash->{current_offset}, 0;
}

sub _set_pos {
  my $self = shift;
  return ( $self->_stash->{current_offset} = tell $self->_stash->{filehandle} );
}

sub _stash  { return ${ *{ $_[0] } }{stash} }
sub _fileno { return }
sub _e      { return 'Data::Handle::Exception::' . shift }
sub _fh     { return shift->_stash->{filehandle} }

sub _binmode {
  return _e('API::NotImplemented')->throw('_binmode() is difficult on Data::Handle and not implemented yet.');
}

sub _open {
  return _e('API::Invalid')->throw('_open() is invalid on Data::Handle.');
}

sub _close {
  return _e('API::Invalid')->throw('_close() is invalid on Data::Handle');
}

sub _printf {
  return _e('API::Invalid')->throw('_printf() is invalid on Data::Handle.');
}

sub _print {
  return _e('API::Invalid')->throw('_print() is invalid on Data::Handle.');
}

sub _write {
  return _e('API::Invalid')->throw('_write() is invalid on Data::Handle.');
}











1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Handle - A Very simple interface to the __DATA__  file handle.

=head1 VERSION

version 1.000001

=head1 SYNOPSIS

    package Foo;

    sub bar {
        my $handle = Data::Handle->new( __PACKAGE__ );
        while (<$handle>) {
            print $_;
        }
    }

    __DATA__
    Foo

=head1 DESCRIPTION

This Package serves as a very I<very> simple interface to a packages __DATA__ section.

Its primary purposes is to make successive accesses viable without needing to
scan the file manually for the __DATA__ marker.

It does this mostly by recording the current position of the file handle on
the first call to C<< ->new >>, and then re-using that position on every successive C<< ->new >> call,
which eliminates a bit of the logic for you.

At present, it only does a simple heuristic ( backtracking ) to verify the current position is B<immediately>
at the start of a __DATA__ section, but we may improve on this one day.

=head1 METHODS

=head2 new

    my $fh = Data::Handle->new( $targetpackage )

Where C<$targetpackage> is the package you want the __DATA__ section from.

=head1 WARNING

At present, this module does you no favors if something else earlier has moved the file handle position past
the __DATA__ section, or rewound it to the start of the file. This is an understood caveat, but nothing else
seems to have a good way around this either. ( You can always rewind to the start of the file and use heuristics, but that is rather pesky ).

Hopefully, if other people B<do> decide to go moving your file pointer, they'll use this module to do it so
you your code doesn't break.

=head1 USAGE

C<Data::Handle->new()> returns a tied file-handle, and for all intents and purposes, it should
behave as if somebody had copied __DATA__ to its own file, and then done C<< open $fh, '<' , $file >>
on it, for every instance of the Data::Handle.

It also inherits from L<IO::File>, so all the methods it has that make sense to use should probably work
on this too,  i.e.:

    my $handle = Data::Handle->new( __PACKAGE__ );
    my @lines = $handle->getlines();

Also, all offsets are proxied in transit, so you can treat the file-handle as if byte 0 is the first byte of the data section.

    my $handle = Data::Handle->new( __PACKAGE__ );
    my @lines = $handle->getlines();
    seek $handle, 0, 0;
    local $/ = undef;
    my $line = scalar <$handle>; # SLURPED!

Also, the current position of each handle instance is internally tracked, so you can have as many
objects pointing to the same __DATA__ section but have their read mechanism uninterrupted by any others.

    my $handlea  = Data::Handle->new( __PACKAGE__ );
    my $handleb  = Data::Handle->new( __PACKAGE__ );

    seek $handlea, 10, 0;
    seek $handleb, 15, 0;

    read $handlea, my $buf, 5;

    read $handleb, my $bufa, 1;
    read $handleb, my $bufb, 1;

     $bufa eq $bufb;

Don't be fooled, it does this under the covers by a lot of C<seek>/C<tell> magic, but they shouldn't be a problem unless you are truly anal over speed.

=head1 CREDITS

Thanks to LeoNerd and anno, from #perl on irc.freenode.org,
they were most helpful in helping me grok the magic of C<tie> that
makes the simplicity of the interface possible.

Thanks to Chas Owens and James Wright for their efforts with trying to get something simpler with fdup()ing the descriptor ( Sadly not working yet ).

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
