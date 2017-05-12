use utf8;
use strict;
use warnings;

package DBIx::DR::PlPlaceHolders;
use Mouse;
extends 'DBIx::DR::PerlishTemplate';
use DBIx::DR::ByteStream;

use Carp ();
use File::Spec ();
use Digest::MD5 ();
use Encode qw(encode);

has sql_dir      => (is => 'bare', isa => 'Str');
has file_suffix  => (is => 'rw', isa => 'Str', default => '.sql.ep');
has helpers      => (is => 'ro', isa => 'HashRef', default => sub {{}});

sub sql_dir {
    my ($self, $dir) = @_;
    if (defined $dir) {
        Carp::croak "Diectory $dir is not found or a dir" unless -d $dir;
        $self->{sql_dir} = File::Spec->rel2abs($dir);
    } elsif(@_ >= 2) {
        $self->{sql_dir} = undef;
    }
    return $self->{sql_dir};
}

sub BUILD {
    my ($self) = @_;

    # add default helpers
    $self->set_helper(
        include => sub {
            my ($tpl, $file, @args) = @_;

            my $res = ref($self)->new(
                pretokens       => $self->prepretokens,
                prepretokens    => $self->prepretokens,
                helpers         => $self->helpers,
                sql_dir         => $self->sql_dir,
                file_suffix     => $self->file_suffix,
            )->sql_transform(
                -f => $file,
                @args
            );


            $tpl->immediate($res->sql);
            $tpl->add_bind_value($res->bind_values);
            return DBIx::DR::ByteStream->new('');
        },

        list  => sub {
            my ($tpl, @args) = @_;
            $tpl->immediate(join ',' => map '?', @args);
            $tpl->add_bind_value(@args);
            return DBIx::DR::ByteStream->new('');
        },

        hlist => sub {
            my ($tpl, @args) = @_;
            if ('ARRAY' eq ref $args[0]) {
                my $filter = shift @args;
                $tpl->immediate(
                    join ',' => (
                        '(' .
                            join(',' => ('?')x @$filter) .
                        ')'
                    )x @args
                );
                for my $a (@args) {
                    $tpl->add_bind_value( map { $a->{$_} } @$filter );
                }
                return DBIx::DR::ByteStream->new('');
            }
            $tpl->immediate(
                join ',' => map {
                    '(' .
                        join(',' => ('?') x keys %$_) .
                    ')'
                } @args
            );
            $tpl->add_bind_value(map { values %$_ } @args);
            return DBIx::DR::ByteStream->new('');
        },

        stacktrace => sub {
            my ($tpl, $skip, $depth, $sep) = @_;

            $depth ||= 32;
            $skip ||= 0;

            $skip += 7;
            $depth += 6;
            $sep = ", " unless defined $sep;

            my @stack;

            for (my $i = $skip ? $skip - 1 : 0; $i < $depth; $i++) {
                my @line = caller $i;
                last unless @line;
                push @stack => sprintf '%s:%s', @line[1,2];
            }
            return DBIx::DR::ByteStream->new(join $sep, @stack);
        },
    );

    $self;
}


sub sql_transform {
    my $self = shift;
    my ($sql, %opts);

    my $pt;

    if (@_ % 2) {
        ($sql, %opts) = @_;
        delete $opts{-f};
    } else {
        %opts = @_;
        Carp::croak $self->usage unless $opts{-f};
        my $file = $opts{-f};

        $file = File::Spec->catfile($self->sql_dir, $file)
            if $self->sql_dir and $file !~ m{^/};
        my $resuffix = quotemeta $self->file_suffix;
        $file .= $self->file_suffix
            if $self->file_suffix and $file !~ /$resuffix$/;

        my @fstat = stat $file;
        Carp::croak "Can't find file $file" unless @fstat;
        $opts{-f} = $file;
    }


    my $namespace = $opts{-f} || $sql;
    $namespace = encode utf8 => $namespace if utf8::is_utf8($namespace);
    $namespace = Digest::MD5::md5_hex($namespace);
    $self->{namespace} = __PACKAGE__ . '::Sandbox::t' . $namespace;

    $self   ->  clean_prepends
            ->  clean_preprepends
    ;

    for my $name (keys %{ $self->helpers }) {
        $self->preprepend(
            'BEGIN{ ' .
                "*" . $name . '= sub {' .
                    '$_PTPL->call_helper(q{' . $name . '}, @_)' .
                '} ' .
            '}'
        );
    }

    my @args;
    for (keys %opts) {
        next unless /^\w/;
        $self->prepend("my \$$_ = shift");
        push @args, $opts{$_};
    }

    if ($sql) {
        $self->render($sql, @args);
    } else {
        $self->render_file($opts{-f}, @args);
    }

    my $res =
        DBIx::DR::PlPlaceHolders::TransformResult->new(rtemplate => $self);

    # clean memory
    $self->{sql} = '';
    $self->{variables} = [];

    $res;
}


sub call_helper {
    my ($self, $name, @args) = @_;
    Carp::croak "Helper '$name' is not found or has already been removed"
        unless exists $self->helpers->{ $name };
    $self->helpers->{ $name }->($self, @args);
}


sub set_helper {
    my ($self, %opts) = @_;
    Carp::croak $self->usage unless %opts;
    while (my ($n, $s) = each %opts) {
        Carp::croak $self->usage unless 'CODE' eq ref $s and $n =~ /^\w/;
        $self->helpers->{ $n } = $s ;
    }
    $self;
}

sub usage {
    my ($self) = @_;
    my @caller = caller 1;

    return 'Usage: $ph->sql_transform($sql | -f => $sql_file, ...)'
        if $caller[3] =~ /sql_transform$/;
    return 'Usage: $ph->set_helper($name => sub { ... })'
        if $caller[3] =~ /set_helper$/;

    return $caller[3];
}

package DBIx::DR::PlPlaceHolders::TransformResult;
use Mouse;

has rtemplate       => (is => 'ro', isa => 'Object', weak_ref => 1);
has sql             => (is => 'ro', isa => 'Str');

sub BUILD {
    my ($self) = @_;
    $self->{sql} = $self->rtemplate->sql;
    $self->{bind_values} = $self->rtemplate->variables;
}

sub bind_values {
    my ($self) = @_;
    return @{ $self->{bind_values} } if wantarray;
    return $self->{bind_values} || [];
}

1;

=head1 NAME

DBIx::DR::PlPlaceHolders - template converter for L<DBIx::DR>.

=head1 COPYRIGHT

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=cut

