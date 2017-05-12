# $Id: /mirror/coderepos/lang/perl/Class-DBI-Plugin-DateTime/trunk/lib/Class/DBI/Plugin/DateTime.pm 101066 2009-02-20T10:00:21.423111Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Class::DBI::Plugin::DateTime;
use strict;
use Module::Pluggable
    sub_name    => 'impls',
    search_path => [ 'Class::DBI::Plugin::DateTime' ],
    except      => [ 'Class::DBI::Plugin::DateTime::Base' ],
    require     => 0,
;
use vars qw($VERSION);
BEGIN {
    $VERSION = '0.05';
}

sub import
{
    my $class = shift;
    my $type  = shift;

    my ($caller) = caller();
    if (!$type) {
        $type  = $caller->db_Main->{Driver}{Name};
    }
    my $impl  = $class->_select_impl($type);

    $impl->_do_export($caller);
}

sub _select_impl
{
    my $class = shift;
    my $type  = lc(shift);

    foreach my $impl ($class->impls) {
        my $p = lc((split(/::/, $impl))[-1]);
        if ($p eq $type) {
            eval "require $impl";
            die if $@;
            return $impl;
        }
    }
}

1;

__END__

=head1 NAME

Class::DBI::Plugin::DateTime - Use DateTime Objects As Columns

=head1 SYNOPSIS

  package MyCDBI;
  # call set_db first
  use Class::DBI::Plugin::DateTime;

  # setup columns, depending on db type

=head1 DESCRIPTION

Class::DBI::Plugin::DateTime is a convenience interface to Class::DBI::Plguin::DateTime::* objects. It auto-detects the connectin type being used, and loads
the appropriate plugin. Note that you need to set up the database connection
before loading this module into your Class::DBI based module.

If you don't want want to bother with this, you can simply use the appropriate
class directly (e.g. Class::DBI::Plugin::DateTime::Pg)

=head1 AUTHOR

Copyright (c) 2005 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>. All rights reserved.

Development funded by Brazil Ltd E<lt>http://b.razil.jpE<gt>

=cut