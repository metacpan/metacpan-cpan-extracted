use strict;
use warnings;

use Test::Most;
use App::Rssfilter::Rule;
use List::MoreUtils;
use Mojo::DOM;

{
    package Test::Match;
    sub match {
        my( $item, @patterns ) = @_;
        unshift @patterns, 'match';
        @patterns = map { qr/\Q$_\E/ } @patterns;
        return List::MoreUtils::any { $item->title->text =~ $_ } @patterns;
    }
}

{
    package Test::Filter;
    sub filter {
        my( $item, $condition_name, %replacements ) = @_;
        %replacements = ( filter => 'WAS_FILTERED', %replacements );
        my $item_description = $item->description->text;
        while( my ($k,$v) = each %replacements ) {
            $item_description =~ s/\Q$k\E/$v/xmseg;
        }
        $item->description->replace_content( $item_description );
    }
}

my $rss = Mojo::DOM->new(<<'END_OF_RSS');
<?xml version=1.0">
<rss>
  <channel>
    <title>Test RSS</title>
    <item>
      <title>match this item and filter it</title>
      <description><![CDATA[hi hello filter me please]]></description>
      <pubdate></pubdate>
      <guid>http://example.org/test/1</guid>
    </item>
  </channel>
</rss>
END_OF_RSS

subtest 'passing match & filter as strings referring to locally declared packages', sub {
    my $string_opt_rule = App::Rssfilter::Rule->new( 'Test::Match' => 'Test::Filter' );
    is(
        $string_opt_rule->condition_name,
        'Test::Match',
        'condition_name defaults to condition attr (if a string)'
    );

    my $string_opt_rss = Mojo::DOM->new( $rss );
    my $count = $string_opt_rule->constrain( $string_opt_rss );

    is(
        $string_opt_rss->find( 'item' )->first->description->text,
        'hi hello WAS_FILTERED me please',
        'looks up match & filter when namespace passed as string'
    );

    is(
        $count,
        1,
        'constrain returns the number of items the rule was applied to'
    );
};

subtest 'passing match & filter as strings with additional arguments', sub {
    my $addn_args_rule = App::Rssfilter::Rule->new( 'Test::Match[heyo]' => 'Test::Filter[house,piece]' );

    my $addn_args_rss = Mojo::DOM->new( $rss );
    $addn_args_rss->at('channel')->append(<<'END_OF_ITEM');
<item>
  <title>heyo here's a new item</title>
  <description><![CDATA[holla up in this house]]></description>
  <pubdate></pubdate>
  <guid>http://example.org/test/2</guid>
</item>
END_OF_ITEM

    is(
        $addn_args_rule->condition_name,
        'Test::Match[heyo]',
        'condition_name is set to condition attr (including additional arguments)'
    );

    my $count = $addn_args_rule->constrain( $addn_args_rss );

    is(
        $addn_args_rss->find( 'item' )->[1]->description->text,
        'holla up in this piece',
        'passed additional args were used when matching and filtering'
    );

    is(
        $count,
        2,
        'constrain returns the number of items the rule was applied to'
    );
};

{
    package App::Rssfilter::Match::Everything;
    sub match {
        1;
    }
};

{
    package App::Rssfilter::Filter::MoreCowbell;
    sub filter {
      my( $item, $condition_name ) = @_;
      $item->description->replace_content('cowbell');
    }
}

subtest 'passing match and filter as non-fully qualified strings', sub {
    my $relative_module_rule = App::Rssfilter::Rule->new( 'Everything' => 'MoreCowbell' );
    my $relative_module_rss =  Mojo::DOM->new( $rss );

    my $count = $relative_module_rule->constrain( $relative_module_rss );

    is(
        $relative_module_rule->condition_name,
        'Everything',
        'condition_name is set before changing condition attr to fully-qualified namespace'
    );

    is(
        $relative_module_rss->find( 'item' )->first->description->text,
        'cowbell',
        'fully qualifies condition attr into the App::Rssfilter::Match:: namespace (likewise for filter)'
    );
};

{
    package ShortName;
    sub match {
        $_[0]->title->text =~ /shortname/xmsi;
    }

    sub filter {
        $_[0]->description->replace_content( 'Short Name is all' );
    }
}

subtest 'passing a fully qualified namespace with leading colons', sub {
    my $fully_qualified_module_rule = App::Rssfilter::Rule->new( '::ShortName' => '::ShortName' );
    my $fully_qualified_module_rss =  Mojo::DOM->new( $rss );
    $fully_qualified_module_rss->at('channel')->append(<<'END_OF_ITEM');
<item>
  <title>has anyone seen shortname</title>
  <description><![CDATA[anyone? Bueller?]]></description>
  <pubdate></pubdate>
  <guid>http://example.org/test/3</guid>
</item>
END_OF_ITEM

    my $count = $fully_qualified_module_rule->constrain( $fully_qualified_module_rss );

    is(
        $fully_qualified_module_rule->condition_name,
        '::ShortName',
        'condition_name is set to namespace'
    );

    is(
        $fully_qualified_module_rss->find( 'item' )->[1]->description->text,
        'Short Name is all',
        'a fully qualified condition attr is not assumed to be in the App::Rssfilter::Match:: namespace (likewise for filter)'
    );
};

subtest 'passing match and filter as strings to modules in INC', sub {
    my $module_rule = App::Rssfilter::Rule->new( 'Category[matchme]' => 'DeleteItem' );
    my $module_rss =  Mojo::DOM->new( $rss );
    $module_rss->find( 'item' )->grep(
        sub {
            my( $item ) = @_;
            defined $item && 'http://example.org/test/1' eq $item->guid->text;
        }
    )->first->append_content( '<category>matchme</category>' );
    my $count = $module_rule->constrain( $module_rss );

    my %seen_items = map { $_->guid->text => $_ } grep { defined } $module_rss->find( 'item' )->each;

    isnt(
        exists $seen_items{ 'http://example.org/test/1' },
        1,
        'modules are loaded on demand'
    );
};

{
    package Test::Match::OO;
    use Moo;
    sub BUILDARGS {
        my( $self, @addn_args ) = @_;
        return { additional_args => \@addn_args };
    }
    has additional_args => (
        is => 'ro',
    );

    sub match {
        my( $self, $item ) = @_;
        my @patterns = map { qr/\Q$_\E/ } @{ $self->additional_args };
        return List::MoreUtils::any { $item->title->text =~ $_ } @patterns;
    }
}

{
    package Test::Filter::OO;
    use Moo;
    sub BUILDARGS {
        my( $self, @addn_args ) = @_;
        return { additional_args => \@addn_args };
    }
    has additional_args => (
        is => 'ro',
    );

    sub filter {
      my( $self, $item, $condition_name ) = @_;
      my %replacements = ( filter => 'WAS_FILTERED', @{ $self->additional_args } );
      my $item_description = $item->description->text;
      while( my ($k,$v) = each %replacements ) {
          $item_description =~ s/\Q$k\E/$v/xmseg;
      }
      $item->description->replace_content( $item_description );
    }
}

subtest 'passing match and filter as strings to OO modules', sub {
    my $oo_rule = App::Rssfilter::Rule->new( 'Test::Match::OO[just this]' => 'Test::Filter::OO[good cop,bad cop]' );

    my $oo_rss =  Mojo::DOM->new( $rss );
    $oo_rss->at('channel')->append(<<'END_OF_ITEM');
<item>
  <title>oo should match just this item</title>
  <description><![CDATA[good cop on the beat]]></description>
  <pubdate></pubdate>
  <guid>http://example.org/test/4</guid>
</item>
END_OF_ITEM

    my $count = $oo_rule->constrain( $oo_rss );

    is(
        $oo_rss->find( 'item' )->[1]->description->text,
        'bad cop on the beat',
        'looks up match & filter when OO module passed as string, and pass addition args to the ctors'
    );
};

subtest 'passing match and filter as OO instances', sub {
    my $oo_rule = App::Rssfilter::Rule->new(
        condition => Test::Match::OO->new('just this'),
        action    => Test::Filter::OO->new("good cop" => "bad cop" ),
    );

    is(
        $oo_rule->condition_name,
        'Test::Match::OO',
        'condition_name uses class name of passed instance'
    );

    my $oo_rss =  Mojo::DOM->new( $rss );
    $oo_rss->at('channel')->append(<<'END_OF_ITEM');
<item>
  <title>oo should match just this item</title>
  <description><![CDATA[good cop on the beat]]></description>
  <pubdate></pubdate>
  <guid>http://example.org/test/4</guid>
</item>
END_OF_ITEM

    my $count = $oo_rule->constrain( $oo_rss );

    is(
        $oo_rss->find( 'item' )->[1]->description->text,
        'bad cop on the beat',
        'uses objects with match or filter methods'
    );
};

subtest 'passing match and filter as anonymous subs', sub {
    my $anon_sub_rule = App::Rssfilter::Rule->new(
        condition => sub {
          $_[0]->title->text =~ /A[.] [ ] Noni [ ] Mouse/xmsi;
        },
        action    => sub {
          $_[0]->description->replace_content( 'Kilroy was here' );
        },
    );

    is(
        $anon_sub_rule->condition_name,
        'unnamed RSS matcher',
        q{condition_name falls back to default if it can't work out the name of condition attr}
    );

    my $anon_sub_rss =  Mojo::DOM->new( $rss );
    $anon_sub_rss->at('channel')->append(<<'END_OF_ITEM');
<item>
  <title>new art work produced by A. Noni Mouse</title>
  <description><![CDATA[picture goes here]]></description>
  <pubdate></pubdate>
  <guid>http://example.org/test/3</guid>
</item>
END_OF_ITEM

    my $count = $anon_sub_rule->constrain( $anon_sub_rss );

    is(
        $anon_sub_rss->find( 'item' )->[1]->description->text,
        'Kilroy was here',
        'match and filter can be anonymous subs'
    );
};

done_testing;
