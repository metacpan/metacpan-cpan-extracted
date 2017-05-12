# NAME

Acme::2zicon - It's new $module

# SYNOPSIS

    use Acme::2zicon;

    my $nizicon = Acme::2zicon->new;

    # retrieve the members on their activities
    my @members         = $nizicon->members;

    # retrieve the members under some conditions
    my @sorted_by_age   = $nizicon->sort('age', 1);
    my @selected_by_age = $nizicon->select('age', 16, '>=');

# DESCRIPTION

# METHODS

## new

    my $nizicon = Acme::2zicon->new;

    Creates and returns a new Acme::2zicon object.

## members

    my @members = $nizicon->members();

## sort ( $type, $order \\\[ , @members \\\] )

    my @sorted_members = $nizicon->sort('age', 1);

## select ( $type, $number, $operator \\\[, @members\\\] )

    # $type can be one of the same values above:
    my @selected_members = $nizicon->select('age', 16, '>=');

    $number $operator $member_value

# LICENSE

MIT License

# AUTHOR

catatsuy &lt;catatsuy@catatsuy.org>

# SEE ALSO

(Japanese text only)

- 虹のコンキスタドール

    [http://pixiv-pro.com/2zicon/](http://pixiv-pro.com/2zicon/)

- プロフィール - 虹のコンキスタドール

    [http://pixiv-pro.com/2zicon/profile](http://pixiv-pro.com/2zicon/profile)

# NOTE

This product has nothing to do with pixiv Inc. and pixiv production Inc. and 2zicon.
