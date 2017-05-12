package App::wmiirc::Tag;
{
  $App::wmiirc::Tag::VERSION = '1.000';
}
# ABSTRACT: Keep track of tags
use App::wmiirc::Plugin;
with 'App::wmiirc::Role::Key';

has last_tag => (
  is => 'rw'
);

my %color;
sub BUILD {
  my($self) = @_;

  %color = map { $_ => "colors " .
    $self->core->main_config->{"${_}colors"} } qw(norm focus alert);

  # Create the tag bar
  wmiir "/lbar/$_", undef for wmiir "/lbar/";
  my($seltag) = wmiir "/tag/sel/ctl";

  for(wmiir "/tag/") {
    next if /sel/;
    s{/}{};
    $self->event_create_tag($_);
    $self->event_focus_tag($_) if $seltag eq $_;
  }
}

sub event_create_tag {
  my($self, $tag) = @_;
  wmiir "/lbar/$tag", $color{norm}, "label $tag";
}

sub event_destroy_tag {
  my($self, $tag) = @_;
  wmiir "/lbar/$tag", undef;
}

sub event_focus_tag {
  my($self, $tag) = @_;
  wmiir "/lbar/$tag", $color{focus};
}

sub event_unfocus_tag {
  my($self, $tag) = @_;
  $self->last_tag($tag);
  wmiir "/lbar/$tag", $color{norm};
}

sub event_urgent_tag {
  my($self, $type, $tag) = @_;
  wmiir "/lbar/$tag", $color{alert};
}

sub event_not_urgent_tag {
  my($self, $type, $tag) = @_;
  my($cur) = wmiir "/tag/sel/ctl";
  wmiir "/lbar/$tag", $cur eq $tag ?  $color{focus} : $color{norm};
}

sub event_left_bar_click {
  my($self, $button, $tag) = @_;
  wmiir "/ctl", "view $tag";
}
*event_left_bar_dnd = \&event_left_bar_click;

sub key_tag_back(Modkey-comma) {
  my($self) = @_;
  $self->key_tag_next(-1);
}

sub key_tag_next(Modkey-period) {
  my($self, $dir) = @_;
  my @tags = sort map s{/$}{}r, grep !/sel/, wmiir "/tag/";
  @tags = reverse @tags if defined $dir && $dir == -1;

  my($cur) = wmiir "/tag/sel/ctl";
  my $l = "";
  for my $tag(@tags) {
    wmiir "/ctl", "view $tag" if $l eq $cur;
    $l = $tag;
  }
  # Wrap around
  wmiir "/ctl", "view $tags[0]" if $l eq $cur;
}

sub key_tag_num(Modkey-#) {
  my(undef, $num) = @_;
  my $tag = $num >= 1 ? $num - 1 : 9;
  my @tags = sort map s{/$}{}r, grep !/sel/, wmiir "/tag/";
  wmiir "/ctl", "view $tags[$tag]" if $tags[$tag];
}

sub key_retag_num(Modkey-Shift-#) {
  my(undef, $tag) = @_;
  wmiir "/client/sel/tags", $tag;
}

sub _tagmenu {
  my @tags = sort map s{/$}{}r, grep !/sel/, wmiir "/tag/";
  wimenu { name => "tag:", history => "tags" }, @tags;
}

sub key_tag_menu(Modkey-t) {
  my($self) = @_;
  my $tag = _tagmenu();
  wmiir "/ctl", "view $tag" if length $tag;
}

sub key_retag_menu(Modkey-Shift-t) {
  my($self) = @_;
  my $tag = _tagmenu();
  wmiir "/client/sel/tags", $tag if length $tag;
}

sub key_retag_go_menu(Modkey-Shift-r) {
  my($self) = @_;
  my $tag = _tagmenu();
  if(length $tag) {
    wmiir "/client/sel/tags", $tag;
    wmiir "/ctl", "view $tag";
  }
}

sub key_tag_swap(Modkey-Tab) {
  my($self) = @_;
  wmiir "/ctl", "view " .  $self->last_tag if $self->last_tag;
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Tag - Keep track of tags

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

