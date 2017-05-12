#
#===============================================================================
#
#         FILE:  MailCap.pm
#
#  DESCRIPTION:  mailcap backend for App::Open
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Erik Hollensbe (), <erik@hollensbe.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  06/03/2008 05:28:27 AM PDT
#     REVISION:  ---
#===============================================================================

package App::Open::Backend::MailCap;

use strict;
use warnings;

use Mail::Cap;
use MIME::Types;

=head1 NAME

App::Open::Backend::MailCap: A backend for using the mailcap system to lookup programs.

=head1 SYNOPSIS

Please read App::Open::Backend for information on how to use backends.

=head1 METHODS

Read App::Open::Backend for what the interface provides, method descriptions
here will only cover implementation.

=over 4

=item new

Takes two args, the filename and a "take" argument that corresponds to the
Mail::Cap constructor argument of the same name, specifying to take the first
mailcap file it finds, or all of them. There is some decision made when either
of these arguments is undef, see load_definitions() for more information.

=cut

sub new {
    my ($class, $args) = @_;

    die "BACKEND_CONFIG_ERROR" if ($args && ref($args) ne 'ARRAY');

    $args ||= [];

    my $self = bless { 
        mailcap_file => $args->[0], 
        mailcap_take => $args->[1] 
    }, $class;

    $self->load_definitions;

    return $self;
}

=item mailcap_file

Return the mailcap filename supplied to the constructor.

=cut

sub mailcap_file { $_[0]->{mailcap_file} }

=item mailcap_take

Return the 'take' argument supplied to the constructor.

=cut

sub mailcap_take { $_[0]->{mailcap_take} }

=item mailcap

Return the Mail::Cap object.

=cut

sub mailcap      { $_[0]->{mailcap} }

=item mime

Return the Mime::Types object.

=cut

sub mime         { $_[0]->{mime} }

=item load_definitions

Load the mailcap definitions and construct Mail::Cap and Mime::Types objects.
This method is called from the constructor; there is no reason to call it
directly.

This method will generate defaults for the `take` argument depending on what is
supplied to the constructor. Basically, if you omit both arguments it will
swallow all mailcap files, if you provide a take argument it will use that. If
you provide a filename it will just use that, and if you supply `ALL` as the
take method and a filename, it will search that file first, then cascade to the
rest of the files on the system.

It could be better.

=cut

sub load_definitions {
    my $self = shift;

    my %mailcap_args;

    foreach my $arg ([qw(mailcap_file filename)],[qw(mailcap_take take)]) {
        $mailcap_args{$arg->[1]} = $self->{$arg->[0]} if ($self->{$arg->[0]});
    }

    #
    # here's a quick rundown:
    #
    # if there are no arguments, "take" is set to "ALL", and the filename is unset.
    # if there is a filename, "take" is set to FIRST unless set otherwise.
    #
    # I think this is the expected behavior when setting a filename; that it be
    # the only one consulted.
    #

    $mailcap_args{take} = "ALL" unless($mailcap_args{take} || $mailcap_args{filename});
    $mailcap_args{take} = "FIRST" if($mailcap_args{filename} && !$mailcap_args{take});

    $self->{mailcap_take} = $mailcap_args{take}; # keep the accessor fresh

    $self->{mailcap} = new Mail::Cap(%mailcap_args);
    $self->{mime}    = new MIME::Types;

    return;
}

=item lookup_file($extension)

Given an extension, it will locate the MIME type for that extension via the
MIME::Types database, and locate the `view` mailcap entry for it, sanitizing it
for templating later.

=cut

sub lookup_file {
    my ($self, $extension) = @_;

    my $program;

    my $type = $self->mime->mimeTypeOf($extension);

    if ($type) {
        $program = $self->mailcap->viewCmd($type, '%s');

        # since we're using the list form of system() underneath, we don't need the
        # quotes... in fact, they'll cause problems.

        $program =~ s/['"]%s['"]/%s/g if ($program);
    }

    return $program;
}

=item lookup_url

Always returns undef. AFAICT mailcap does not support URLs.

=cut

sub lookup_url { undef }

=back

=head1 LICENSE

This file and all portions of the original package are (C) 2008 Erik Hollensbe.
Please see the file COPYING in the package for more information.

=head1 BUGS AND PATCHES

Probably a lot of them. Report them to <erik@hollensbe.org> if you're feeling
kind. Report them to CPAN RT if you'd prefer they never get seen.

=cut

1;
