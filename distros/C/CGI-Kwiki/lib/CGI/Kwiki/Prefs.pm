package CGI::Kwiki::Prefs;
$VERSION = '0.18';
use strict;
use base 'CGI::Kwiki';
use CGI::Kwiki;

attribute 'error_msg';

sub pref_fields {
    qw(
        user_name 
        select_diff
        show_diff
        show_changed
    );
}

attribute($_) for pref_fields();

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->driver->load_class('cookie');
    my $prefs = $self->driver->cookie->prefs;
    for my $pref ($self->pref_fields) {
        $self->$pref(defined $prefs->{$pref} ? $prefs->{$pref} : '')
          unless defined $self->$pref;
    }
    return $self;
}

sub all {
    my ($self) = @_;
    map {
        my $pref = $_;
        ($pref, $self->$pref());
    } $self->pref_fields;
}

sub process {
    my ($self) = @_;
    $self->error_msg('');
    $self->save 
      if $self->cgi->button eq 'SAVE';
    $self->cgi->page_id($self->config->preferences_page);
    return
      $self->template->process('display_header') .
      $self->template->process('prefs_body',
          error_msg => $self->error_msg,
          $self->all,
      ) .
      $self->template->process('basic_footer');
}

sub save {
    my ($self) = @_;
    for my $pref ($self->pref_fields) {
        $self->$pref($self->cgi->$pref);
    }
    unless ($self->user_name eq '' or 
            $self->database->exists($self->user_name)
           ) {
        $self->error_msg(
          '<p>' . $self->loc("Username must be a valid wiki page (about yourself).") . '</p>'
        );
        return;
    }
    $self->driver->cookie->prefs({$self->all});
}
    
1;

__END__

=head1 NAME 

CGI::Kwiki::Prefs - Preferences Base Class for CGI::Kwiki

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
