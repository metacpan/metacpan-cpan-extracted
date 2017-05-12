package Bot::BasicBot::Pluggable::Module::Vars;
$Bot::BasicBot::Pluggable::Module::Vars::VERSION = '1.20';
use base qw(Bot::BasicBot::Pluggable::Module);
use warnings;
use strict;

sub help {
    return
"Change internal module variables. Usage: !set <module> <variable> <value>, !unset <module> <variable>, !vars <module>.";
}

sub told {
    my ( $self, $mess ) = @_;
    my $body = $mess->{body};
    return 0 unless defined $body;
    my ( $command, $mod, $var, $value ) = split( /\s+/, $body, 4 );
    $command = lc($command);

    return if !$self->authed( $mess->{who} );

    if ( $command eq "!set" ) {
        my $module = $self->{Bot}->module($mod);
        return "No such module '$module'." unless $module;
        $value = defined($value) ? $value : '';    # wipe if no value.
        $module->set( "user_$var", $value ) if $var;
        return "Set.";

    }
    elsif ( $command eq "!unset" ) {
        return "Usage: !unset <module> <variable>." unless $var;
        my $module = $self->{Bot}->module($mod);
        return "No such module '$module'." unless $module;
        $module->unset("user_$var");
        return "Unset.";

    }
    elsif ( $command eq "!vars" ) {
        return "You must pass a module" unless defined $mod;
        my $module = $self->bot->module($mod);
        return "No such module '$mod'." unless $module;
        my @vars =
          map { my $mod = $_; $mod =~ s/^user_// ? $mod : () }
          $module->store_keys( res => ["^user"] );
        return "$mod has no variables." unless @vars;
        return "Variables for $mod: "
          . (
            join ", ", map { "'$_' => '" . $module->get("user_$_") . "'" } @vars
          ) . ".";
    }
}

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::Vars - change internal module variables

=head1 VERSION

version 1.20

=head1 SYNOPSIS

Bot modules have variables that they can use to change their behaviour. This
module, when loaded, gives people who are logged in and authenticated the
ability to change these variables from the IRC interface. The variables
that are set are in the object store, and begin "user_", so:

  !set Module foo bar

will set the store key 'user_foo' to 'bar' in the 'Module' module.

=head1 IRC USAGE

=over 4

=item !set <module> <variable> <value>

Sets the variable to value in a given module. Module must be loaded.

=item !unset <module> <variable>

Unsets a variable (deletes it entirely) for the current load of the module.

=item !vars <module>

Lists the variables and their current values in a module.

=back

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
