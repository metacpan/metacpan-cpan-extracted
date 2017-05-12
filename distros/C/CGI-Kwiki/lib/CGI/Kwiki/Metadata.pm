package CGI::Kwiki::Metadata;
$VERSION = '0.18';
use strict;
use base 'CGI::Kwiki';

sub all {
    my ($self) = @_;
    %{$self->get};
}

sub get {
    my ($self, $page_id, @keys) = @_;
    $page_id ||= $self->cgi->page_id;
    my $file_path = "metabase/metadata/" . $self->escape($page_id);
    my $metadata = {};
    if (-f $file_path) {
        open METADATA, $file_path 
          or return $metadata;
        binmode(METADATA, ':utf8') if $self->use_utf8;
        for (<METADATA>) {
            if (/(\w+):\s+(.*?)\s*$/) {
                $metadata->{$1} = $2;
            }
        }
        close METADATA;
    }
    return @{$metadata}{@keys} if @keys;
    return $metadata;
}

sub set {
    my ($self, $page_id, @key_values) = @_;
    my $file_path = "metabase/metadata/" . $self->escape($page_id);
    umask 0000;
    open METADATA, "> $file_path" or die $!;
    binmode(METADATA, ':utf8') if $self->use_utf8;
    my $template = $self->metadata_template;
    print METADATA $self->driver->template->render($template,
        edit_by => $self->edit_by,
        edit_time => scalar(gmtime),
        @key_values,
    );
    close METADATA;
}

sub edit_by {
    my ($self) = @_;
    $self->driver->cookie->prefs->{user_name} ||
    $CGI::Kwiki::user_name ||
    ''; 
}

sub metadata_template {
    <<END;
edit_by: [% edit_by %] 
edit_time: [% edit_time %] 
END
}

1;

__DATA__

=head1 NAME 

CGI::Kwiki::Database - Page Metadata Storage for CGI::Kwiki

=head1 DESCRIPTION

See installed kwiki pages for more information.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
