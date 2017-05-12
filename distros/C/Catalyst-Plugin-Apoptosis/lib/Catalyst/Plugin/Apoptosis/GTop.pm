# $Id: /mirror/perl/Catalyst-Plugin-Apoptosis/trunk/lib/Catalyst/Plugin/Apoptosis/GTop.pm 2552 2007-09-18T08:36:57.555445Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Catalyst::Plugin::Apoptosis::GTop;
use strict;
use base qw(Catalyst::Plugin::Apoptosis Class::Data::Inheritable);
use GTop;
BEGIN
{
    if (my $code = GTop->can('THREADED')) {
        if (! $code->()) {
            delete $INC{'threads.pm'};
        }
    }
}

__PACKAGE__->mk_classdata($_) for qw(gtop);

sub setup
{
    my ($class, @arguments) = @_;

    $class->NEXT::setup(@arguments);
    $class->gtop(GTop->new);

    $class->config->{apoptosis}{gtop} ||= {};
}

sub check_apoptosis_condition
{
    my $class = shift;
    my $pm = $class->gtop->proc_mem($$);

    my $config = $class->config->{apoptosis}{gtop};
    foreach my $field qw(size vsize resident share rss) {
        my $limit = $config->{$field};
        defined $limit or next;
        my $value = $pm->$field;
        if ($value > $limit) {
            $class->log->info("Apoptosis condition reached. Bailing out")
                if $class->log->is_info;
            Catalyst::Exception::Apoptosis->throw(message => "Apoptosis condition reached ($field [$value] > $limit)");
        }
    }
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Apoptosis::GTop - Check Condition Based On GTop

=head1 METHODS

=head2 setup

=head2 check_apoptosis_condition

=cut