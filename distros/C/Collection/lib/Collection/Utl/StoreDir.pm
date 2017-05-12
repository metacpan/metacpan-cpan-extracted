package Collection::Utl::StoreDir;

=head1 NAME

Collection::Utl::StoreDir - Simple store/restore data to files in dirs.

=head1 SYNOPSIS

    use Collection::Utl::StoreDir;
    my $fz = IO::Zlib->new($tmp_file, "rb");
    my $dir = tempdir( CLEANUP => 0 );
    my $temp_store = new Collection::Utl::StoreDir:: $dir;
    $temp_store->putRaw("file.dat",$fz);
    $fz->close;

=head1 DESCRIPTION

Simple store/restore data to files in dirs.

=head1 METHODS

=cut

use IO::File;
use File::Path;
use Data::Dumper;
use warnings;
use Encode;
use Carp;
use strict;
my $attrs = { _dir => undef };
### install get/set accessors for this object.
for my $key ( keys %$attrs ) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$key" } = sub {
        my $self = shift;
        $self->{$key} = $_[0] if @_;
        return $self->{$key};
      }
}

sub new {
    my $class = shift;
    my $obj;
    if ( ref $class ) {
        $obj   = $class;
        $class = ref $obj;
    }
    my $self = bless( {}, $class );
    if (@_) {
        my $dir = shift;
        if ($obj) {
            $dir =~ s%^/%%;
            $dir = $obj->_dir . $dir;
        }
        $dir .= "/" unless $dir =~ m%/$%;
        $self->_dir($dir);
    }
    else {
        carp "need path to dir";
        return;
    }
    return $self;
}

sub _store_data {
    my ( $self, $mode, $name, $val ) = @_;
    return unless defined $val;
    my $file_name = $self->_get_path . $name;
    my $out = new IO::File:: "> $file_name" or die $!;
    local $/;
    $/ = undef;
    my ($atime, $mtime);
    if ( ref $val ) {
        if (   UNIVERSAL::isa( $val, 'IO::Handle' )
            or ( ref $val eq 'GLOB' )
            or UNIVERSAL::isa( $val, 'Tie::Handle' ) )
        {
            $out->print(<$val>);
            #set atime and mtime
            ($atime, $mtime) = (stat $val )[8,9];
            $val->close;
        }
        else {
            $out->print(
                ( $mode =~ /utf8/ ) ? $self->_utfx2utf($$val) : $$val );
        }
    }
    else {
        $out->print( ( $mode =~ /utf8/ ) ? $self->_utfx2utf($val) : $val );
    }
    $out->close or die $!;
    if ( $atime && $mtime) {
        utime $atime, $mtime, $file_name;
    }

}

sub _utfx2utf {
    my ( $self, $str ) = @_;
    $str = encode( 'utf8', $str ) if utf8::is_utf8($str);
    return $str;
}

sub _utf2utfx {
    my ( $self, $str ) = @_;
    $str = decode( 'utf8', $str ) unless utf8::is_utf8($str);
    return $str;
}

sub _get_path {
    my $self = shift;
    my $key  = shift;
    my $dir  = $self->_dir;
    mkpath( $dir, 0 ) unless -e $dir;
    return $dir;
}

sub putText {
    my $self = shift;
    return $self->_store_data( ">:utf8", @_ );
}

sub putRaw {
    my $self = shift;
    return $self->_store_data( ">", @_ );
}

sub getRaw_fh {
    my $self = shift;
    my $key  = shift;
    my $fh   = new IO::File:: "< " . $self->_dir . $key or return;
    return $fh;
}

sub getRaw {
    my $self = shift;
    if ( my $fd = $self->getRaw_fh(@_) ) {
        my $data;
        {
            local $/;
            undef $/;
            $data = <$fd>;
        }
        $fd->close;
        return $data;
    }
    else { return }
}

sub getText {
    my $self = shift;
    return $self->_utf2utfx( $self->getRaw(@_) );
}

sub getText_fh {
    my $self = shift;
    return $self->getRaw_fh(@_);
}

sub get_path_to_key {
    my $self = shift;
    my $key  = shift;
    my $dir  = $self->_dir;
    return $dir . $key;
}

sub get_keys {
    my $self = shift;
    my $dir  = $self->_dir;
    return [] unless -e $dir;
    opendir DIR, $dir or die $!;
    my @keys = ();
    while ( my $key = readdir DIR ) {
        next if $key =~ /^\.\.?$/ or -d "$dir/$key";
        push @keys, $key;
    }
    return \@keys;
}

=head3 delete_keys <key1>[,<key2>[,<keyX>]]

Delete files from dir

=cut
sub delete_keys {
    my $self = shift;
    my $dir  = $self->_dir;
    unlink "$dir/$_" for (@_) 
}

sub clean {
    my $self = shift;
    my $dir  = $self->_dir;
    rmtree( $dir, 0 );
}
1;
__END__

=head1 SEE ALSO

IO::File

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

