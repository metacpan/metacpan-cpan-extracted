package Beagle::Cmd::Command::help;
use Beagle::Util;
use Any::Moose;

extends qw/Beagle::Cmd::GlobalCommand App::Cmd::Command::help/;

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opts, $args ) = @_;

    my $alias        = alias;
    if ( $alias->{$args->[0]} ) {
        puts qq!"$args->[0]" is aliased to "$alias->{$args->[0]}".!;
        return;
    }

    my ($cmd) = $self->app->prepare_command(@$args);
    exit 1
      if ref $cmd eq 'Beagle::Cmd::Command::commands'
          && $args->[0] ne 'commands';

    require Pod::Usage;
    require Pod::Find;

    $cmd->usage->{options} = [
        sort { $a->{desc} cmp $b->{desc} }
        grep { $_->{name} ne 'help' } @{ $cmd->usage->{options} }
    ];

    # '' is for a newline
    my $opt = join newline(), 'OPTIONS', $cmd->usage->option_text, '';

    my $out;
    open my $fh, '>', \$out or die $!;
    Pod::Usage::pod2usage(
        -verbose   => 2,
        -input     => Pod::Find::pod_where(
            { -inc => 1 },
            ref $cmd
        ),
        -output => $fh,
        -exitval => 'NOEXIT',
    );
    close $fh;

    # users don't want to see AUTHOR and COPYRIGHT normally
    if ( $self->verbose ) {
        unless ( $out =~ s!(?=^AUTHOR)!$opt!m ) {
            $out .= $opt;
        }
    }
    else {
        $out =~ s!^AUTHOR.*!!sm;
        $out .= $opt;
    }
    puts $out;
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::help - show beagle help


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

