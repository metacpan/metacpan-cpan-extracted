package App::Caoliu::Parser;

# ABSTRACT: parser caoliu rss and bbs page
use Mojo::Base "Mojo";
use Mojo::DOM;
use Carp;
use Mojo::Log;
use Mojo::Collection;
use Encode qw(decode encode);
use App::Caoliu::Utils qw(get_video_size trim dumper);
use utf8;

has xml => sub {
    return Mojo::DOM->new->xml(1);
};
has html => sub {
    return Mojo::DOM->new;
};
has log => sub {
    $ENV{LOGGER} || Mojo::Log->new;
};

sub parse_rss {
    my ( $self, $xml_string ) = @_;
    my @items = ();

    for my $item (
        $self->xml->parse( decode( 'GBK', $xml_string ) )->find('item')->each )
    {
        push @items,
          {
            description => $item->at('description')->text,
            link        => $item->at('link')->text,
            category    => $item->at('category')->text,
            pubdate     => $item->at('pubdate')->text,
          };
    }

    return Mojo::Collection->new(@items);
}

sub parse_post {
    my ( $self, $post_string ) = @_;

    return unless $post_string;

    my $post_hashref = {};
    my $html         = decode( 'GBK', $post_string );
    my $dom          = $self->html->parse($html);

    if ( my $part = $dom->at('div.tpc_content') ) {
        eval {
            my $encoded_data = encode( 'utf8', $part );
            my $title = $dom->at('h4')->all_text;
            if( $title =~ m{\[(.+?)\](.*)} ){
                my ($format,$raw_size) = split('/',$1);
                $post_hashref->{name} = trim($2);
                $post_hashref->{format} = $format;
                $post_hashref->{size} = get_video_size($raw_size) if $raw_size;
            }
            $post_hashref->{name} = trim($1)
              if $part =~ m{【影片(?:名稱|名称)】: (.*?)<br}six;
            $post_hashref->{format} = trim($1)
              if $part =~ m{【(?:影片格式|格式类型)】: (.*?)<br}six;
            $post_hashref->{size} = get_video_size($1)
              if $part =~ m{【影片大小】: (.*?)<br}six;
            $post_hashref->{vc} = trim($1)
              if $part =~ m{【验证编码】: (.*?)<br}six;
            $post_hashref->{code_option} = trim($1)
              if $part =~ m{【有码无码】: (.*?)<br}six;
            if ( $part =~ m{【下载地址】: (.*?)<br}six ) {
                $post_hashref->{download_link} = $dom->parse($1)->at('a')->text;
            }
            ( $post_hashref->{post_date} ) = $post_string=~ m{Posted:(\d{4}-\d{2}-\d{2}\s+\d+:\d+)}six;
            $post_hashref->{rmdown_link} = trim($1)
              if $part =~ m{(http://www.rmdown.com.+?hash=.+?)</a>}six;
            $post_hashref->{preview_imgs} = Mojo::Collection->new;
            push @{ $post_hashref->{preview_imgs} }, $_->{src}
              for $part->find('img')->each;
        };
    }
    $self->log->debug( "got post_info :" . dumper($post_hashref) );

    return $post_hashref;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME 

App::Caoliu::Parser

=head1 SYNOPSIS

    my $p = App::Caoliu::Parser->new;
    $p->parse_rss($rss_xml);
    $p->parse_post($post_html);
    $p->log->debug("say something");

=AUTHOR



=cut




