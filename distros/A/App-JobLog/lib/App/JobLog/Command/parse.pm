package App::JobLog::Command::parse;
$App::JobLog::Command::parse::VERSION = '1.042';
# ABSTRACT: parse a time expression

use App::JobLog -command;
use autouse 'App::JobLog::TimeGrammar' => qw(parse);

use Modern::Perl;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $expression = join ' ', @$args;
    eval {
        my ( $s, $e, $is_interval ) = parse $expression;
        say <<END;
        
received:          $expression
start time:        $s
end time:          $e
received interval: @{[$is_interval ? 'true' : 'false']}
END
    };
    $self->usage_error($@) if $@;
}

sub validate {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error('no time expression provided') unless @$args;
}

sub usage_desc { '%c ' . __PACKAGE__->name }

sub abstract { 'parse a time expression' }

sub full_description {
    <<END
If you are getting strange results with @{[App::JobLog::Command::summary->name]}, the problem
might be the time expression you're using. This command lets you see how your expression is
getting parsed.

It repeats to you the phrase it has parsed, prints out the start and end time of the corresponding
interval, and finally, whether it understands itself to have received an expression of the form
<date> or <date> <separator> <date>, the latter form being called an "interval" for diagnostic
purposes.
END
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::parse - parse a time expression

=head1 VERSION

version 1.042

=head1 DESCRIPTION

If you are getting strange results with summary, the problem
might be the time expression you're using. This command lets you see how your expression is
getting parsed.

It repeats to you the phrase it has parsed, prints out the start and end time of the corresponding
interval, and finally, whether it understands itself to have received an expression of the form
<date> or <date> <separator> <date>, the latter form being called an "interval" for diagnostic
purposes.

=head1 SEE ALSO

L<App::JobLog::TimeGrammar>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
