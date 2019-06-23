package Code::TidyAll::Plugin::Spellunker;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Moo;

extends 'Code::TidyAll::Plugin';

use Spellunker;

use Specio::Declare;
use Specio::Library::Builtins;

has stopwords => (
    is      => 'ro',
    isa     => anon(
        parent => t('Str'),
        where  => sub { $_[0] =~ /^ \s* [^,]+ (?: \s* ,[^,]+ )* \s* $/xo },
    ),
    default => q{},
);

has parsed_stopwords => (
    is  => 'lazy',
    isa => t('ArrayRef'),
);

## no critic (ProhibitUnusedPrivateSubroutines)
sub _build_parsed_stopwords {
    my $self = shift;
    return [split /\s*,\s*/x, $self->stopwords];
}
## use critic (ProhibitUnusedPrivateSubroutines)

sub validate_source {
    my ($self, $source) = @_;

    my @errors = $self->_check_source($source);
    return unless @errors;

    my $msg = _stringify_errors(@errors);
    die $msg; ## no critic (RequireCarping)
}

sub _check_source {
    my ($self, $source) = @_;

    my $engine = Spellunker->new();
    $engine->add_stopwords(@{ $self->parsed_stopwords });

    my @errors;

    my $lineno = 0;
    for my $line (split quotemeta $/, $source) {
        $lineno++;

        my @line_errors = $engine->check_line($line);
        next unless @line_errors;

        push @errors => [
            $lineno,
            $line,
            \@line_errors,
        ];
    }

    return @errors;
}

sub _stringify_errors {
    my @errors = @_;

    my $msg = "Errors:\n";
    for (@errors) {
        my ($lineno, $line, $errs) = @$_;
        for my $err (@$errs) {
            $msg .= "    $lineno: $err\n";
        }
    }
    return $msg;
}

1;
__END__

=encoding utf-8

=head1 NAME

Code::TidyAll::Plugin::Spellunker - Code::TydyAll plugin for Spellunker

=head1 SYNOPSIS

    [Spellunker]
    select = doc/**/*.txt
    stopwords = karupanerura

    [Spellunker::Pod]
    select = lib/**/*.{pm,pod}
    stopwords = karupanerura

=head1 DESCRIPTION

Code::TidyAll::Plugin::Spellunker is Code::TydyAll plugin for Spellunker.

=head1 OPTIONS

=head2 stopwords

Add stopwords to the on memory dictionary. Separate it by ",".

SEE ALSO: https://metacpan.org/pod/Spellunker#$spellunker-%3Eadd_stopwords(@stopwords)

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

