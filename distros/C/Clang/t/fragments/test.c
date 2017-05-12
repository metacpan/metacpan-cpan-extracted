void foo(int arg) {
	int a = argp + 5;

	return a;
}

int main(int argc, char *argv[]) {
	int a = foo(argc);

	return a;
}
