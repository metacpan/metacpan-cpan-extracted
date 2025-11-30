!ru:en
# NAME

Aion::Format::Html - библиотека для форматирования HTML

# SYNOPSIS

```perl
use Aion::Format::Html;

from_html "<b>&excl;</b>" # => !
to_html "<a>"             # => &lt;a&gt;
```

# DESCRIPION

Библиотека для форматирования HTML-документов.

# SUBROUTINES

## from_html ($html)

Преобразует HTML в текст.

```perl
from_html "Basic is <b>superlanguage</b>!<br>"  # => Basic is superlanguage!\n
```

## to_html ($html)

Экранирует символы HTML.

## safe_html ($html)

Обрезает опасные и неизвестные теги HTML, а также неизвестные атрибуты из известных тегов.

```perl
safe_html "-<em>-</em><br>-" # => -<em>-</em><br>-
safe_html "-<em onclick='  '>-</em><br onmouseout=1>-" # => -<em>-</em><br>-
safe_html "-<xx24>-</xx24>" # => --
safe_html "-< applet >-</ applet >" # => -< applet >-
```

## split_on_pages ($html, $symbols_on_page, $by)

Разбивает текст на страницы с учетом html-тегов.

```perl
[split_on_pages "Alice in wonderland. This is book", 17]  # --> ["Alice in wonderland. ", "This is book"]
```

# AUTHOR

Yaroslav O. Kosmina <darviarush@mail.ru>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Format::Html module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
