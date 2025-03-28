#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Backend::Fstab 2.155;

use Mouse;
use Carp;
use Log::Log4perl qw(get_logger :levels);

extends 'Config::Model::Backend::Any';

my $logger = get_logger("Backend::Fstab");

sub annotation { return 1; }

my %opt_r_translate = (
    ro      => 'rw=0',
    rw      => 'rw=1',
    bsddf   => 'statfs_behavior=bsddf',
    minixdf => 'statfs_behavior=minixdf',
);

sub read {
    my $self = shift;
    my %args = @_;

    # args are:
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # check      => yes|no|skip

    return 0 unless $args{file_path}->exists;    # no file to read
    my $check = $args{check} || 'yes';

    my @lines = $args{file_path}->lines_utf8;

    # try to get global comments (comments before a blank line)
    $self->read_global_comments( \@lines, '#' );

    my @assoc = $self->associates_comments_with_data( \@lines, '#' );
    foreach my $item (@assoc) {
        my ( $data, $comment ) = @$item;
        $logger->trace("fstab read data '$data' comment '$comment'");

        my ( $device, $mount_point, $type, $options, $dump, $pass ) =
            split /\s+/, $data;

        my $swap_idx = 0;
        my $label =
              $device =~ /LABEL=(\w+)$/ ? $1
            : $type eq 'swap'           ? "swap-" . $swap_idx++
            :                             $mount_point;

        my $fs_obj = $self->node->fetch_element('fs')->fetch_with_id($label);

        if ($comment) {
            $logger->trace("Annotation: $comment\n");
            $fs_obj->annotation($comment);
        }

        my $load_line = "fs_vfstype=$type fs_spec=$device fs_file=$mount_point "
            . "fs_freq=$dump fs_passno=$pass";
        $logger->debug("Loading:$load_line\n");
        $fs_obj->load( step => $load_line, check => $check );

        # now load fs options
        $logger->trace("fs_type $type options is $options");
        my @options;
        foreach ( split /,/, $options ) {
            my $o = $opt_r_translate{$_} // $_;
            $o =~ s/no(.*)/$1=0/;
            $o .= '=1' unless $o =~ /=/;
            push @options, $o;
        }

        $logger->debug("Loading:@options");
        $fs_obj->fetch_element('fs_mntopts')->load( step => "@options", check => $check );
    }
    return 1;
}

sub write {
    my $self = shift;
    my %args = @_;

    # args are:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # check      => yes|no|skip

    my $node = $args{object};

    croak "Undefined file handle to write" unless defined $args{file_path};

    my $res = $self->write_global_comment( '#' );

    # Using Config::Model::ObjTreeScanner would be overkill
    foreach my $line_obj ( $node->fetch_element('fs')->fetch_all ) {
        my $d = sprintf(
            "%-30s %-25s %-6s %-10s %d %d\n",
            (map { $line_obj->fetch_element_value($_); } qw/fs_spec fs_file fs_vfstype/),
            $self->option_string( $line_obj->fetch_element('fs_mntopts') ),
            (map { $line_obj->fetch_element_value($_); } qw/fs_freq fs_passno/),
        );
        $res .= $self->write_data_and_comments( '#', $d, $line_obj->annotation );

    }

    $args{file_path}->spew_utf8($res);
    return 1;
}

my %rev_opt_r_translate = reverse %opt_r_translate;

sub option_string {
    my ( $self, $obj ) = @_;

    my @options;
    foreach my $opt ( $obj->get_element_name ) {
        my $v = $obj->fetch_element_value($opt);
        next unless defined $v;
        my $key = "$opt=$v";
        my $str =
              defined $rev_opt_r_translate{$key} ? $rev_opt_r_translate{$key}
            : "$v" eq '0'                        ? 'no' . $opt
            : "$v" eq '1'                        ? $opt
            :                                      $key;
        push @options, $str;
    }

    return join ',', @options;
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Read and write config from fstab file

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Backend::Fstab - Read and write config from fstab file

=head1 VERSION

version 2.155

=head1 SYNOPSIS

No synopsis. This class is dedicated to configuration class C<Fstab>

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with C<fstab> syntax in
C<Config::Model> configuration tree. Typically this backend is
used to read and write C</etc/fstab>.

=head1 Comments in file_path

This backend is able to read and write comments in the C</etc/fstab> file.

=head1 STOP

The documentation below describes methods that are currently used only by 
L<Config::Model>. You don't need to read it to write a model.

=head1 CONSTRUCTOR

=head2 new

Parameters: C<< ( node => $node_obj, name => 'fstab' ) >>

Inherited from L<Config::Model::Backend::Any>. The constructor is
called by L<Config::Model::BackendMgr>.

=head2 read

Of all parameters passed to this read call-back, only C<file_path> is
used. This parameter must be a L<Path::Tiny> object.

When a file is read, C<read> returns 1.

=head2 write

Of all parameters passed to this write call-back, only C<file_path> is
used.

C<write> returns 1.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::BackendMgr>, 
L<Config::Model::Backend::Any>, 

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005-2022 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
