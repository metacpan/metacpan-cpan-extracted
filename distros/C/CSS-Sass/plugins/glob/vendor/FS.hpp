#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>
#include <string>
#include <vector>
#include <iostream>

namespace FS {

	class Root;
	class Entry;
	class Match;

	// implementation for asterisk matching
	// http://stackoverflow.com/q/30823596/1550314
	// not sure if this work 100% correctly with backtracking
	// but good starting point to add more pattern matchings
	bool pmatch(const std::string& text, const std::string& pattern);

	static std::string getDriveLetter(std::string path) {
		if (path[0] == '/' || path[0] == '\\') return "/";
		else if (path[0] && path[1] == ':') {
			if (path[2] == '/') return path.substr(0, 2);
			if (path[2] == '\\') return path.substr(0, 2);
			return path.substr(0, 2) + ".";
		}
		return ".";
	}

	// Directory entry
	class Entry {

		friend class Root;
		friend class Match;

		protected:
			bool matched;
			bool collapse;
			bool directory;
			bool loaded;
			bool fetched;
			Entry* parent;
			std::string name;
			std::vector<Entry*> entries;

		protected:
			// constructor need at least a name
			// the name should not be empty (check)
			Entry(const std::string& name, Entry* parent) :
				matched(false),
				collapse(false),
				directory(true),
				loaded(false),
				fetched(false),
				parent(parent),
				name(name),
				entries()
			{ };

		public:
			// Deconstructor
			~Entry ()
			{
				// call delete on all entries (pointer array)
				const std::vector<Entry*>& entries = this->entries;
				std::vector<Entry*>::const_iterator it = entries.begin();
				while (it != entries.end()) { delete (*it); ++ it; }
			}

		public:
			bool operator<(Entry rhs) const
			{
				return name < rhs.name;
			}

		public:
			// copy constructor
			/* Entry(const Entry& entry) :
				matched(entry.matched),
				directory(entry.directory),
				loaded(entry.loaded),
				fetched(entry.fetched),
				parent(entry.parent),
				name(entry.name),
				entries(entry.entries)
			{ }; */
			// default assignment operator
			/* Entry& operator=(const Entry& rhs)
			{
				this->name = rhs.name;
				this->entries = rhs.entries;
				this->matched = rhs.matched;
				this->directory = rhs.directory;
				this->loaded = rhs.loaded;
				this->fetched = rhs.fetched;
				this->parent = rhs.parent;
				return *this;
			} */

		public:
			// test if node is a directory
			bool isDirectory()
			{
				// check if state was already determined
				if (this->fetched) return this->directory;
				// query the inode
				struct stat inode;
				// get the full path for node
				std::string path(this->path());
				// call the sys-function
				stat(path.c_str(), &inode);
				// test if the node is a directory
				this->directory = S_ISDIR(inode.st_mode);
				// update status flag
				this->fetched = true;
				// return the status
				return this->directory;
			}

		protected:
			// main method to get our sub children
			const std::vector<Entry*>& getEntries();

		protected:
			// adding file or directory
			// fill be determined later
			void add(std::string name)
			{
				// create new object on the stack
				Entry* entry = new Entry(name, this);
				// push entry object to children
				// will be freed on descruction
				entries.push_back(entry);
			}
			// EO add

		public:
			// return full path
			const std::string path() const;

		public:
			// return path with trailing slash
			const std::string directry() const
			{
				return this->path() + "/";
			}
			// return stored name
			const std::string getName() const
			{
				return this->name;
			}
			// apply pattern against node name
			bool match(const std::string& pattern) const
			{
				return pmatch(this->name, pattern);
			}

		private:
	};

	// expose initial constructor
	class Root : public Entry {
		public:
			// constructor for root
			// relative or absolute
			Root(const std::string& name) :
				Entry(name, this)
			{
				// Entry* root = new Entry("", this);
				// create entry levels for
				// absolute root filesystems
				// ensures that `/.*` matches
				if (name != ".") {
					this->add(std::string("."));
					this->add(std::string(".."));
				}
			}

		private:
	};

	class Match {

		friend class Root;
		friend class Entry;

		private:
			Root root;
			size_t lvl;
			bool executed;
			bool directory;
			std::vector<Entry*> matches;
			std::vector<std::string> patterns;

		public:
			// constructor needs only a pattern
			// we create the needed FS::Root
			Match (const std::string& pattern) :
				// create root (detect relative search pattern)
				root(getDriveLetter(pattern)),
				lvl(0), executed(false), directory(false)
			{
				// this->add(std::string(root.name));

				// get iterators to parse pattern into directories
				std::string::const_iterator it = pattern.begin();
				std::string::const_iterator end = pattern.end();
				std::string::const_iterator cur = it;

				// do we have a driveletter?
				if (root.name.size() > 1) {
					this->add(std::string(root.name));
					// name already added
					it += 2;
					// skip over possible
					while (*it == '/' || *it == '\\') it ++;
					cur = it;
				}

				// add pattern match for relative entry point
				else if (root.name == ".") this->add(".");

				// parse pattern
				while (it != end) {
					// found directory delimiter
					if (*it == '/' || *it == '\\') {
						// append directory substring
						this->add(std::string(cur, it));
						while (*it == '/' || *it == '\\') it ++;
						// move iterator
						cur = it;
					}
					// advance
					++ it;
				}
				// EO while parse

				// have some rest?
				if (cur <= it) {
					// append directory substring
					this->add(std::string(cur, it));
				}
				// EO last item

			}
			// get matches paths from pattern
			// executes only once on first call
			std::vector<Entry*> getMatches()
			{
				// check if already executed
				if (this->executed == false) {
					// call execute

					this->execute(this->root);
					// update status flag
					this->executed = true;
				}
				// return matches
				return this->matches;
			}

		protected:
			// add directory part matcher
			// track directory status and
			// skip over repeated slashes
			void add(std::string name)
			{
				// skip over repeated empty names (slashes)
				if (this->directory && name.empty()) return;
				// append the pattern partial
				this->patterns.push_back(name);
				// update directory status flag
				this->directory = name.empty();
			}

		protected:
			// run the matcher, which in turn will
			// call getEntries to query filesystem
			void execute(Entry& entry);

		protected:
			// apply match recusively
			void recursive(Entry& entry);

		private:
	};

}
