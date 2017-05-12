package Acme::Albed;

use utf8;
use Any::Moose;

our $VERSION = '0.03';

has albedian => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has dict => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $dict = {
            a   => { before => 'あいうえお', after => 'ワミフネト', },
            ka  => { before => 'かきくけこ', after => 'アチルテヨ', },
            sa  => { before => 'さしすせそ', after => 'ラキヌヘホ', },
            ta  => { before => 'たちつてと', after => 'サヒユセソ', },
            na  => { before => 'なにぬねの', after => 'ハシスメオ', },
            ha  => { before => 'はひふへほ', after => 'マリクケロ', },
            ma  => { before => 'まみむめも', after => 'ヤイツレコ', },
            ya  => { before => 'やゆよ',       after => 'タモヲ', },
            ra  => { before => 'らりるれろ', after => 'ナニウエノ', },
            wa  => { before => 'わをん',       after => 'カムン', },
            ga  => { before => 'がぎぐげご', after => 'ダヂヅデゾ', },
            za  => { before => 'ざじずぜぞ', after => 'バビブゲボ', },
            da  => { before => 'だぢづでど', after => 'ガギグベゴ', },
            ba  => { before => 'ばびぶべぼ', after => 'ザジズゼド', },
            pa  => { before => 'ぱぴぷぺぽ', after => 'プポピパペ', },
            la  => { before => 'ぁぃぅぇぉ', after => 'ァィゥェォ', },
            ltu => { before => 'っゃゅょ',    after => 'ッャュョ', },
            en  => {
                before => 'abcdefghijklmnopqrstuvwxyz',
                after  => 'ypltavkrezgmshubxncdijfqow',
            },
        };
        return $dict;
    },
);

sub to_albed {
    my ( $self, $arg ) = @_;
    return unless defined $arg;
    $self->albedian(0);
    $self->_conv($arg);
}

sub from_albed {
    my ( $self, $arg ) = @_;
    return unless defined $arg;
    $self->albedian(1);
    $self->_conv($arg);
}

sub _conv {
    my ( $self, $message ) = @_;
    my $res;
    my $dict    = $self->dict;
    my @mos     = keys(%$dict);
    my @message = split //, $message;
    for my $i ( 0 .. $#message ) {
        my $char = $message[$i];
        if ( $char =~ /(\s|\t|\n)/ ) {
            $res .= $char;
        }
        else {
            return unless ( defined $char && $char ne "" );
            my $enc;
            foreach my $key (@mos) {
                $" = "|";
                my ( $source, $conv ) = $self->_resource( $dict->{$key} );
                my @source = split //, $source;
                my @conv   = split //, $conv;
                if ( $char =~ /(@source)/ ) {
                    for my $i ( 0 .. $#source ) {
                        if ( $char eq $source[$i] ) {
                            $enc = $conv[$i];
                        }
                    }
                }
            }
            if (defined $enc) {
                $res .= $enc;
            } else {
                $res .= $char;
            }
        }
    }
    return $res;
}

sub _resource {
    my ( $self, $dict ) = @_;
    if ( $self->albedian ) {
        return ( $dict->{after}, $dict->{before} );
    }
    else {
        return ( $dict->{before}, $dict->{after} );
    }
}
1;
__END__

=head1 NAME

Acme::Albed - Convert from/to Albedian.

=head1 SYNOPSIS

  use Acme::Albed;
  my $albed = Acme::Albed->new;
  my $albedian = $albed->to_albed("...");
  my $hiragana = $albed->from_albed("...");

=head1 DESCRIPTION

Acme::Albed convert from/to Albedian.
Albedian is fiction language on FinalFantasy X, and simple substitution cipher. 

=head1 AUTHOR

haoyayoi E<lt>st.hao.yayoi@gmail.comE<gt>

=head1 SEE ALSO

http://ja.wikipedia.org/wiki/%E3%82%A2%E3%83%AB%E3%83%99%E3%83%89%E8%AA%9E

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
