package CGI::Kwiki::Privacy;
$VERSION = '0.16';
use strict;
use CGI::Kwiki qw(encode decode escape unescape);

sub all {
    my ($self) = @_;
    (
        has_privacy => $self->has_privacy,
        is_admin => $self->is_admin,
        not_admin => $self->not_admin,
        script => $self->script,
    );
}

sub is_readable {
    my ($self, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;
    return $self->is_admin || 
           not $self->is_private($page_id);
}

sub is_writable {
    my ($self, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;
    return $self->is_admin || 
           not ($self->is_private($page_id) || 
                $self->is_protected($page_id)
               );
}

sub is_editable {
    my ($self, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;
    return $self->is_admin || 
           not $self->is_protected($page_id);
}

sub is_admin {
    my ($self) = @_;
    $CGI::Kwiki::ADMIN and $self->has_privacy;
}

sub not_admin {
    my ($self) = @_;
    not $CGI::Kwiki::ADMIN and $self->has_privacy;
}

sub is_public {
    my ($self, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;
    -f "metabase/public/" . $self->escape($page_id);
}

sub is_protected {
    my ($self, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;
    -f "metabase/protected/" . $self->escape($page_id);
}

sub is_private {
    my ($self, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;
    -f "metabase/private/" . $self->escape($page_id);
}

sub has_privacy {
    -d "metabase/public";
}

sub set_privacy {
    my ($self, $privacy, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;
    return unless $self->has_privacy;
    my $is_method = "is_$privacy";
    return if $self->$is_method($page_id);
    for (qw(private protected public)) {
        $is_method = "is_$_";
        my $privacy_file = "metabase/$_/" . $self->escape($page_id);
        if ($_ eq $privacy) {
            open PRIVACY, "> $privacy_file"
              or die "Can't open $privacy_file:\n$!";
            print PRIVACY ' ';
            close PRIVACY;
            my $umask = umask 0000;
            chmod(0666, $privacy_file);
            umask $umask;
        }
        elsif ($self->$is_method($page_id)) {
            unlink "$privacy_file"
              or die "Can't unlink $privacy_file";
        }
    }
}

# Name of the current script
sub script {
    my $script = $0;
    $script =~ s/.*[\\\/]//;
    return $script;
}

sub use_utf8 { ($] >= 5.008) }

1;

__END__

=head1 NAME 

CGI::Kwiki::Privacy - Privacy Base Class for CGI::Kwiki

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
