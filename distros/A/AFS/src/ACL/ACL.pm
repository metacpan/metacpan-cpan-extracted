package AFS::ACL;
#------------------------------------------------------------------------------
# RCS-Id: "@(#)$RCS-Id: src/ACL/ACL.pm 7a64d4d Wed May 1 22:05:49 2013 +0200 Norbert E Gruener$"
#
# © 2001-2011 Norbert E. Gruener <nog@MPA-Garching.MPG.de>
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#------------------------------------------------------------------------------

use AFS ();

use vars qw(@ISA $VERSION);

@ISA     = qw(AFS);
$VERSION = 'v2.6.4';

sub new {
    my ($this, $class);
    # this whole construct is to please the old version from Roland
    if ($_[0] =~ /AFS::ACL/) {
        $this  = shift;
        $class = ref($this) || $this;
    }
    else {
        $class = 'AFS::ACL';
    }

    my $pos_rights = shift;
    my $neg_rights = shift;

    my $self  = [{}, {}];
    if (defined $pos_rights) { %{$self->[0]} = %$pos_rights; }
    if (defined $neg_rights) { %{$self->[1]} = %$neg_rights; }

    bless $self, $class;
}

sub copy {
    my $self = shift;

    my $class = ref($self) || $self;
    my $new   = [{}, {}];

    %{$new->[0]} = %{$self->[0]};
    %{$new->[1]} = %{$self->[1]};
    bless $new, $class;
}

sub apply {
    my $self   = shift;
    my $path   = shift;
    my $follow = shift;

    $follow = 1 unless defined $follow;
    AFS::setacl($path, $self, $follow);
}

sub retrieve {
    my $class  = shift;
    my $path   = shift;
    my $follow = shift;

    $follow = 1 unless defined $follow;
    AFS::_getacl($path, $follow);
}

sub modifyacl {
    my $self   = shift;
    my $path   = shift;
    my $follow = shift;

    my $newacl;

    $follow = 1 unless defined $follow;
    if ($newacl = AFS::_getacl($path, $follow)) {
        $newacl->add($self);
        AFS::setacl($path, $newacl, $follow);
    }
    else { return 0; }
}

sub copyacl {
    my $class  = shift;
    my $from   = shift;
    my $to     = shift;
    my $follow = shift;

    my $acl;

    $follow = 1 unless defined $follow;
    if ($acl = AFS::_getacl($from, $follow)) { AFS::setacl($to, $acl, $follow); }
    else { return 0; }
}

sub cleanacl {
    my $class  = shift;
    my $path   = shift;
    my $follow = shift;

    my $acl;

    $follow = 1 unless defined $follow;
    if (! defined ($acl = AFS::_getacl($path, $follow))) { return 0; }
    if ($acl->is_clean) { return 1; }
    AFS::setacl($path, $acl, $follow);
}

sub crights {
    my $class = shift;

    AFS::crights(@_);
}

sub ascii2rights {
    my $class  = shift;

    AFS::ascii2rights(@_);
}

sub rights2ascii {
    my $class = shift;

    AFS::rights2ascii(@_);
}

# old form  DEPRECATED !!!!
sub addacl {
    my $self = shift;
    my $macl = shift;

    foreach my $key ($macl->keys)  { $self->set($key, $macl->get($key)); }
    foreach my $key ($macl->nkeys) { $self->nset($key, $macl->nget($key)); }
    return $self;
}

sub add {
    my $self = shift;
    my $acl  = shift;

    foreach my $user ($acl->get_users)  { $self->set($user,  $acl->get_rights($user)); }
    foreach my $user ($acl->nget_users) { $self->nset($user, $acl->nget_rights($user)); }
    return $self;
}

sub is_clean {
    my $self = shift;

    foreach ($self->get_users, $self->nget_users) { return 0 if (m/^-?\d+$/); }
    return 1;
}

# comment Roland Schemers: I hope I don't have to debug these :-)
sub empty      { $_[0] = bless [ {},{} ]; }
sub get_users  { CORE::keys %{$_[0]->[0]}; }
sub length     { int(CORE::keys %{$_[0]->[0]}); }
sub get_rights { ${$_[0]->[0]}{$_[1]}; }
sub exists     { CORE::exists ${$_[0]->[0]}{$_[1]}; }
sub set        { ${$_[0]->[0]}{$_[1]} = $_[2]; }
sub remove     { delete ${$_[0]->[0]}{$_[1]}; }
sub clear      { $_[0]->[0] = {}; }

sub keys { CORE::keys %{$_[0]->[0]}; }    # old form:  DEPRECATED !!!!
sub get  { ${$_[0]->[0]}{$_[1]}; }        # old form:  DEPRECATED !!!!
sub del  { delete ${$_[0]->[0]}{$_[1]}; } # old form:  DEPRECATED !!!!


# comment Roland Schemers: same for negative entries
sub nget_users  { CORE::keys %{$_[0]->[1]}; }
sub nlength     { int(CORE::keys %{$_[0]->[1]}); }
sub nget_rights { ${$_[0]->[1]}{$_[1]}; }
sub nexists     { CORE::exists ${$_[0]->[1]}{$_[1]}; }
sub nset        { ${$_[0]->[1]}{$_[1]} = $_[2]; }
sub nremove     { delete ${$_[0]->[1]}{$_[1]}; }
sub nclear      { $_[0]->[1] = {}; }

sub nkeys { CORE::keys %{$_[0]->[1]}; }    # old form:  DEPRECATED !!!!
sub nget  { ${$_[0]->[1]}{$_[1]}; }        # old form:  DEPRECATED !!!!
sub ndel  { delete ${$_[0]->[1]}{$_[1]}; } # old form:  DEPRECATED !!!!

1;
