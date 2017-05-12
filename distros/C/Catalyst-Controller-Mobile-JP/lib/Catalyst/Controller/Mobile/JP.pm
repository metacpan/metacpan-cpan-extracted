package Catalyst::Controller::Mobile::JP;
use strict;
use warnings;
our $VERSION = '0.02';

use base qw( Catalyst::Controller Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( encoding ));

use Encode;
use Encode::JP::Mobile ':props';
use Encode::JP::Mobile::Character;
use HTTP::MobileAgent::Plugin::Charset;

sub begin :Private {
    my ($self, $c) = @_;
    
    $self->encoding(do {
        my $encoding = $c->req->mobile_agent->encoding;
        ref($encoding) && $encoding->isa('Encode::Encoding')
            ? $encoding
            : Encode::find_encoding($encoding);
    });
    
    for my $value (values %{ $c->req->{parameters} }) {
        next if ref $value && ref $value ne 'ARRAY';
         
        for my $v (ref($value) ? @$value : $value) {
            next if Encode::is_utf8($v);
            $v = $self->encoding->decode($v);
        }
    }
    
    $c->res->content_type(do {
        if ($c->req->mobile_agent->is_docomo) {
            'application/xhtml+xml';
        } else {
            'text/html; charset=' . $self->encoding->mime_name;
        }
    });
}

my %htmlspecialchars = ( '&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;' );
my $htmlspecialchars = join '', keys %htmlspecialchars;

our $decoding_content_type = qr{^text|xml$|javascript$};

sub end :Private {
    my ($self, $c) = @_;
    
    my $body = $c->res->body;
    if ($body and
        not ref($body) and
        $c->res->content_type =~ $decoding_content_type) {
        
        $body = $self->encoding->encode($body, sub {
            my $char = shift;
            my $out  = Encode::JP::Mobile::FB_CHARACTER()->($char);
            
            if ($c->res->content_type =~ /html$|xml$/) {
                $out =~ s/([$htmlspecialchars])/$htmlspecialchars{$1}/ego; # for (>３<)
            }

            $out;
        });
         
        $c->res->body($body);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Catalyst::Controller::Mobile::JP - decode/encode with Encode::JP::Mobile

=head1 SYNOPSIS

  package MyApp;
  use Catalyst qw/ MobileAgent /;
  
  ...
   
  package MyApp::Controller::Root;
  use strict;
  use base 'Catalyst::Controller::Mobile::JP';
  
  __PACKAGE__->config->{namespace} = '';
  
  sub foo :Local {
      my ($self, $c) = @_;
      
      $c->res->body(
          $c->req->param('text') . "\x{E72A}"
      );
  }

=head1 DESCRIPTION

Catalyst::Controller::Mobile::JP works as a base controller
that automatically decode()/encode() with the recommended encoding
lead from values of UserAgent.

You can use unicode in your app that includes cross-carrier pictograms.

このモジュールは Catalyst::Controller で、SYNOPSIS にあるように使います。
C<begin> で C<< $c->req->params >> の Encode::decode()、C<end> で
C<< $c->res->body >> の Encode::encode() を行ないます。

エンコーディングは UserAgent の値を元に L<Encode::JP::Mobile> から
おすすめのものが利用されます（L<HTTP::MobileAgent::Plugin::Charset>）ので、
アプリケーション内部では特に意識せずキャリアをまたいだ絵文字を含む文字情報を
Unicode として扱うことができます。

=head1 ACCESSOR

=over 4

=item encoding

利用されるエンコーディングの L<Encode::Encoding> オブジェクトが
入っています。

  $self->encoding->name;      # x-sjis-docomo
  $self->encoding->mime_name; # Shift_JIS

=back

=head1 USE WITH CUSTOM end() METHOD

コントローラーで C<begin> や C<end> を実装する場合は、以下のように
C<next::method> でこのモジュールのメソッドを呼んでください。

  sub render :ActionClass('RenderView') {
  
  }
  
  sub end :Private {
      my ($self, $c) = @_;
      
      $c->stash->{encoding} = $self->encoding;
      $c->forward('render');
  
      $self->next::method($c);
  }

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 DEVELOPMENT

L<http://coderepos.org/share/browser/lang/perl/Catalyst-Controller-Mobile-JP> (repository)

#mobilejp on irc.freenode.net (I've joined as "tomi-ru")

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Encode::JP::Mobile>, L<HTTP::MobileAgent::Plugin::Charset>,
L<Catalyst::View::MobileJpFilter>

=cut
