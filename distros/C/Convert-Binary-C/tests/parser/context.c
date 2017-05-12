enum bar
{
  bar = 1
};

typedef int foo;

struct foo
{
  int foo : bar;
  int bar;
  int def;
};

// TODO: make parser accept commented lines

static int xyz(int foo)
{
  int bar = 0;
  // foo = bar + 1;
  // return foo + bar;
}

static foo abc(foo foo)
{
  // return foo + bar;
}

typedef foo def;

int main(void)
{
  foo foo = abc(42);
  int abc = bar;
  // struct foo bar = { bar: 0, foo: foo, def: abc };
  // foo += bar.def + bar.foo;
  // return foo + bar.bar + xyz(foo);
}
