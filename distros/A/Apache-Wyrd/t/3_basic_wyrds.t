use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw(GET_BODY GET_OK);

plan tests => 15;

ok t_cmp("success", GET_BODY '/1.html', "Wyrd Load");
ok t_cmp("test\n", GET_BODY '/2.html?test=1', "CGICond on");
ok t_cmp("\n", GET_BODY '/2.html', "CGICond off");
ok t_cmp("1 2 3\n", GET_BODY '/3.html?anna=3&an=2&annabella=1', "Interfaces/Setter");
ok t_cmp("variable: test\n", GET_BODY '/5.html?variable=test&something=else', "Var by name");
ok t_cmp("variable: else\n", GET_BODY '/6.html?variable=test&something=else', "Var by param");
ok t_cmp("variable: this template\n", GET_BODY '/7.html', "Template");
ok t_cmp("variable: Nil\n", GET_BODY '/9.html', "Attribute");
ok t_cmp("<UL><LI>time: 1, 2</UL>\n", GET_BODY '/8.html?time=1&time=2', "ShowParams");
ok t_cmp("variable: N'i\"l\n", GET_BODY '/12.html', "enclosed single quotes");
ok t_cmp("variable: N'i'l\n", GET_BODY '/10.html', "enclosed single quotes");
ok t_cmp("variable: N\"i\"l\n", GET_BODY '/11.html', "enclosed double quotes");
ok t_cmp("This is a cached file.", GET_BODY '/14.html', "File Caching/Lib");
ok t_cmp('$12,345,678.8765', GET_BODY '/17.html', "File Caching/Lib");
ok t_cmp('Forty-six', GET_BODY '/18.html', "File Caching/Lib");
