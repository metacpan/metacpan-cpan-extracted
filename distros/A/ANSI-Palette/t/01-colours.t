use Test::More;

use ANSI::Palette qw/all/;

text_8(32, "This is a test for text_8\n");
text_16(32, 1, "This is a test for text_16\n");
text_256(32, "This is a test for text_256\n");

bold_8(0, "This is a test for bold_8\n");
underline_8(0, "This is a test for underline_8\n");
italic_8(0, "This is a test for italic_8\n");


background_text_8(30, 41, "Hello\n");
background_text_16(30, 0, 101, "Hello\n");
background_bold_16(30, 0, 101, "Hello\n");
background_underline_16(30, 0, 101, "Hello\n");
background_italic_16(30, 0, 101, "Hello\n");


background_text_256(208, 33, "This is a test for background_text_256\n");
background_bold_256(208, 33, "This is a test for background_bold_256\n");
background_underline_256(208, 33, "This is a test for background_underline_256\n");
background_italic_256(208, 33, "This is a test for background_italic_256\n");

ok(1);

done_testing();
