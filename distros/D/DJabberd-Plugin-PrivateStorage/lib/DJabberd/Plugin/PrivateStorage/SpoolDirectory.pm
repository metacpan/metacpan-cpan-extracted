package DJabberd::Plugin::PrivateStorage::SpoolDirectory;
use strict;
use base 'DJabberd::Plugin::PrivateStorage';
use warnings;
use File::Path;
use URI::Escape;
use File::Slurp;
use File::Basename;

=head2 get_file_name($self, $user,  $element)

Get the filename that should hold information for this combination of $user and 
$element. The variable are escaped in order to prevent problem with various char, like
"/".

=cut

sub get_file_name {
    my ($self, $user, $element) = @_;
    my ($login, $domain) = split(/@/, $user);
    $login = uri_escape($login);
    $domain = uri_escape($domain);
    $element = uri_escape($element);
    #~ $ perl -MURI::Escape -e 'print uri_escape("http://coin.foo.org/plop:ezez/"),"\n"
    #http%3A%2F%2Fcoin.foo.org%2Fplop%3Aezez%2F
    return $self->{directory} . "/$domain/$login/$element.xml"
}

=head2 set_config_directory($self, $val)

Set the directory that will be used a base of the spool directory.
It will be created if it doesn't exist.

=cut

sub set_config_directory {
    my ($self, $val) = @_;
    $self->{directory} = $val;
}

=head2 finalize($self)

Check that plugin was correctly initialized.

=cut


sub finalize {
    my ($self) = @_;
    die "Missing directory" if not defined $self->{directory};
    # TODO ensure permisison ?
    mkpath($self->{directory}) if ! -d $self->{directory};
    die if ! -d $self->{directory};
}

=head2 load_privatestorage($self, $user,  $element)

Load the element $element for $user from memory.

=cut

sub load_privatestorage {
    my ($self, $user,  $element) = @_;
    my $filename = $self->get_file_name($user, $element);
    return undef if ! -f $filename;
    return read_file($filename);
}

=head2 store_privatestorage($self, $user,  $element, $content)

Store $content for $element and $user in memory.

=cut

sub store_privatestorage {
    my ($self, $user, $element, $content) = @_;
    my $filename = $self->get_file_name($user, $element);
    
    mkpath(dirname($filename)) if ! -d dirname($filename);

    write_file($filename, $content->as_xml);
}
1;

__END__

=head1 NAME

DJabberd::Plugin::PrivateStorage::SpoolDirectory - implement private storage, stored in a spool directory

=head1 SYNOPSIS

  <Plugin DJabberd::Plugin::PrivateStorage::SpoolDirectory>
      Directory "/var/spool/djabberd/private_storage/"
  </Plugin>

=head1 DESCRIPTION

This plugin is derived from DJabberd::Plugin::PrivateStorage. It implement a spool directory storage, 
similar to the one used by jabberd, or postfix ( for the mail ). The filename is derived from username
and the namespace used. Directory will be autocreated if it doesn't exist.

=head1 COPYRIGHT

This module is Copyright (c) 2006 Michael Scherer
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 AUTHORS

Michael Scherer <misc@zarb.org>
