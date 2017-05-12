package App::JobLog::Command;
$App::JobLog::Command::VERSION = '1.042';
# ABSTRACT: common functionality of App::JobLog commands

use App::Cmd::Setup -command;
use Modern::Perl;
use App::JobLog::Config qw(columns);

sub opt_spec {
    my ( $class, $app ) = @_;

    return ( $class->options($app), [ 'help' => "this usage screen" ] );
}

# makes sure everything has some sort of description
sub description {
    my ($self) = @_;

    # abstract provides default text
    my $desc = $self->full_description;
    unless ($desc) {
        ( $desc = $self->abstract ) =~ s/^\s++|\s++$//g;

        # ensure initial capitalization
        $desc =~ s/^(\p{Ll})/uc $1/e;

        # add sentence-terminal punctuation as necessary
        $desc =~ s/(\w)$/$1./;
    }

    # make sure things are wrapped nicely
    _wrap( \$desc );

    # space between description and options text
    $desc .= "\n";
    return $desc;
}

# performs text wrapping while preserving the formatting of lines beginning with whitespace
sub _wrap {
    my $desc = shift;
    require Text::WrapI18N;
    $Text::WrapI18N::columns = columns;
    my ( $current, @gathered );
    for my $line ( $$desc =~ /^(.*?)\s*$/mg ) {
        if ( $line =~ /^\S/ ) {
            if ($current) {
                $current .= " $line";
            }
            else {
                $current = $line;
            }
        }
        else {
            push @gathered, Text::WrapI18N::wrap( '', '', $current )
              if defined $current;
            push @gathered, $line;
            $current = undef;
        }
    }
    push @gathered, Text::WrapI18N::wrap( '', '', $current )
      if defined $current;
    $$desc = join "\n", @gathered;
}

# override to make full description
sub full_description { }

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    die $self->_usage_text if $opt->{help};
    $self->validate( $opt, $args );
}

# obtains command name
sub name {
    ( my $command = shift ) =~ s/.*:://;
    return $command;
}

# by default a command has no options other than --help
sub options { }

# by default a command does no argument validation
sub validate { }

# add to simple commands after argument signature so they'll complain if given arguments
sub simple_command_check {
    my ( $self, $args ) = @_;
    $self->usage_error("This command does not expect any arguments! No action taken.") if @$args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command - common functionality of App::JobLog commands

=head1 VERSION

version 1.042

=head1 DESCRIPTION

B<App::JobLog::Command> adds a small amount of specialization and functionality to L<App::Cmd> commands. In
particular it adds a C<--help> option to every command and ensures that they all have some minimal longer
form description that can be obtained with the C<help> command.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
