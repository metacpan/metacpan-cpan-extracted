#include <iostream>
#include <cstring>
#include "FS.hpp"

// implement simple command line tool
int main(int argc, char** argv)
{

	// unquote all arguments
	for (size_t i = 1; i < argc; i += 1) {
		// very dumb unquote function
		size_t len = strlen(argv[i]) - 1;
		// check if start and end matches single/double quote
		bool quoted = (argv[i][0] == '"' && argv[i][len] == '"')
		           || (argv[i][0] == '\'' && argv[i][len] == '\'');
		// and remove quotes from both sides
		if (quoted) { argv[i][len] = 0; argv[i] += 1; }
		// check if start and end matches double quote
		if (argv[i][0] == '"' && argv[i][len] == '"') {
			// remove from both sides
			argv[i][len] = 0; argv[i] += 1;
		}
	}

	// get the only supported argument
	// this is the pattern to match against
	// mostly quoted to avoid shell expansion
	const char* arg = argc == 1 ? "*" : argv[1];
	// std::cerr << "search for " << arg << std::endl;

	// instantiate the matcher instance
	FS::Match* matcher = new FS::Match(arg);

	// get vector of matches (results are cached)
	const std::vector<FS::Entry*> matches = matcher->getMatches();

	// iterate over the list and print out the results
	std::vector<FS::Entry*>::const_iterator it = matches.begin();
	std::vector<FS::Entry*>::const_iterator end = matches.end();
	while (it != end) std::cout << (*it++)->path() << std::endl;

}
