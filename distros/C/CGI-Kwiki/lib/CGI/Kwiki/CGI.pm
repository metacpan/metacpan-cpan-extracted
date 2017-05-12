package CGI::Kwiki::CGI;
$VERSION = '0.16';
use strict;
use base 'CGI::Kwiki';
use CGI::Kwiki ':char_classes';

sub all {
    my ($self) = @_;
    return (
        CGI::Vars(), 
        page_id => $self->page_id,
        map { ($_, $self->{$_}) } 
        grep { not /^(cgi|config|driver)$/ } keys %$self
    );
}

sub wiki_text {
    my ($self) = shift;
    if (not defined $self->{wiki_text}) {
        $self->{wiki_text} = CGI::param('wiki_text');
        $self->{wiki_text} =~ s/\015\012/\n/g;
        $self->{wiki_text} =~ s/\015/\n/g;
        $self->{wiki_text} =~ s/\n*\z/\n/;
        $self->{wiki_text} = '' if $self->{wiki_text} eq "\n";
        $self->decode($self->{wiki_text});
    }
    return $self->{wiki_text} 
}

sub action {
    my ($self) = shift;
    if (@_) {
        $self->{action} = shift;
        return $self;
    }
    my $action = CGI::param('action') || '';
    $action = '' if $action =~ /[^$WORD]/;
    return $action || 'display';
}

sub page_id {
    my ($self) = shift;
    if (@_) {
        $self->{page_id} = shift;
        return $self;
    }
    return $self->{page_id} 
      if defined $self->{page_id};
    my $page_id = '';
    my $query_string = CGI::query_string();
    $query_string =~ s/%([0-9a-fA-F]{2})/pack("H*", $1)/ge;
    $self->decode($query_string);
    if ($query_string =~ /^keywords=([$ALPHANUM\-:]+)$/) {
        $page_id = $1;
    }
    elsif ($self->action eq 'search') {
        $page_id = $self->search eq '' ? $self->loc('SiteMap') : $self->loc('SearchResults');
    }
    else {
        $page_id = CGI::param('page_id') || 
                   $self->config->top_page ||
                   '';
        $self->decode($page_id);
    }
    $page_id = '' if $page_id =~ /[^$ALPHANUM\-\:]/;
    return $page_id || $self->config->top_page || '';
}

sub blog_id {
    my ($self) = shift;
    my $query_string = CGI::query_string();
    my $blog_id = ($query_string =~ /^keywords=(\d{14})$/) ? $1 : '';
    return $blog_id;
}

sub button {
    my ($self) = shift;
    my %params = $self->all;
    while (my ($k, $v) = each %params) {
        return uc($1) if $k =~ /^button-(\w+)$/;
    }
}

use vars qw($AUTOLOAD);
sub AUTOLOAD {
    my $param = $AUTOLOAD;
    $param =~ s/.*://;
    my ($self) = shift;
    if (@_) {
        $self->{$param} = shift;
        return $self;
    }
    my $value = $self->get_raw($param);
    $value =~ s/[^$WORD\-\:\.\,\|\ ]//g;
    return $value;
}

sub get_raw {
    my ($self, $param) = @_;
    my $value = defined $self->{$param} 
      ? $self->{$param}
      : CGI::param($param);
    $value = '' unless defined $value;
    $self->decode($value);
    return $value;
}

1;

__END__

=head1 NAME 

CGI::Kwiki::CGI - CGI Base Class for CGI::Kwiki

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
