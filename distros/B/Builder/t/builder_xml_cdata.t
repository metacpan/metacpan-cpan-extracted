use Test::More tests => 2;
use Builder;

my $builder = Builder->new();
my $with_cdata = $builder->block( 'Builder::XML', { cdata => 1 } );
my $without_cdata = $builder->block( 'Builder::XML' );
my $text  = "Tom, Dick & Harry";
my $text2 = lc $text;

# test 1
$with_cdata->body( sub {
    $with_cdata->span($text);
    $with_cdata->span( $with_cdata->__cdata__( $text2 ) );
});
is $builder->render, data("<![CDATA[$text]]>", $text2), "xml cdata test 1";

# test 2
$without_cdata->body( sub {
    $without_cdata->span($text);
    $without_cdata->span( $without_cdata->__cdata__( $text2 ) );
});
is $builder->render, data($text, $text2), "xml cdata test 2";

sub data {
    return qq{<body><span>$_[0]</span><span><![CDATA[$_[1]]]></span></body>};
}


__END__

 '<body><span><!CDATA[[Tom, Dick & Harry]]></span><span><!CDATA[[<!CDATA[[tom, dick & harry]]>]]></span></body>'
 '<body><span><!CDATA[[Tom, Dick & Harry]]></span><span><!CDATA[[tom, dick & harry]]></span></body>'