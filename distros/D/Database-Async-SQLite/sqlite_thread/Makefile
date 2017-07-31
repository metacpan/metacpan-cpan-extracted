OBJ = sqlite_thread.o sqlite_dbh.o sqlite_sth.o sqlite_queue.o

all: $(OBJ) libsqlite_thread.a

$(OBJ): %.o: %.cpp
	$(CC) -xc++ -c $(CFLAGS) $(CPPFLAGS) -fPIC -std=c++11 -I. $< -o $@

libsqlite_thread.a:  $(OBJ)
	ar rcs libsqlite_thread.a $^
