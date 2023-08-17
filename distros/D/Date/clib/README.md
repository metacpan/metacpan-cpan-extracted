# Panda-Date

Panda-Date - extremely fast Date C++ framework with timezones, microseconds, relative dates and intervals support.

# How to Use
If you are familliar with CMake and find_package then you already know what to do.
Your project should use CMake to use Panda-Date. It does not neigther download nor install its dependencies. It should be observeble with [find_package](https://cmake.org/cmake/help/latest/command/find_package.html).  There are several ways to achive it. In any case you will need the following list of dependencies:
* Panda-Lib [https://github.com/CrazyPandaLimited/panda-lib](https://github.com/CrazyPandaLimited/panda-lib)
* [Optional] Catch2 [https://github.com/catchorg/Catch2](https://github.com/catchorg/Catch2)

Catch2 is used for tests. Tests are disabled by default. To turn it on set PANDA_DATE_TESTS=ON.

#### Option 1: add_subdirectory
Clone all dependencies and Panda-Date itself anywhere to your project directory. Add following lines to CMakeLists.txt
```cmake
#add_subdirectory(clone_dir/Catch2 ${CMAKE_CURRENT_BINARY_DIR}/modules/Catch2)
add_subdirectory(clone_dir/panda-lib ${CMAKE_CURRENT_BINARY_DIR}/modules/panda-lib)
add_subdirectory(clone_dir/Date ${CMAKE_CURRENT_BINARY_DIR}/modules/Date)

target_link_libraries(your_target_name panda-date)
```
Where `clone_dir` is place where you cloned dependencies, `your_target_name` is target of your project that depends on Panda-Date. Second argument of `add_subdirectory` is build dir, use any other directory you like.
#### Option 2: Build and Install Manually
First you need a directory for installed dependencies of your project, e.g. cmake/prefix. It can be anywhere and usually outside of project. Clone all dependencies and Panda-Date itself anywhere to any folder (in or outside of project). Then run the following script in each cloned folder:

```bash
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX:PATH=cmake/prefix
cmake --build .
cmake --build . --target install
```
Add following lines to your CMakeLists.txt
```cmake
find_package(panda-date REQUIRED)
target_link_libraries(your_target_name panda-date)
```
Set CMAKE_MODULE_PATH to your folder on build step of Panda-Date. If you run cmake manually:
```bash
cmake .. -DCMAKE_MODULE_PATH=cmake/prefix
```

# API Reference

Panda-Date was created as perl module. Perl documentation can be found here [https://metacpan.org/dist/Date/view/lib/Date.pod](https://metacpan.org/dist/Date/view/lib/Date.pod)
C++ documentation is in progress.

# Development

[Ragel](http://www.colm.net/open-source/ragel/) is used to build parser. Generated files are commited to repo, so you do not need anything to build it. But if you want to change grammar you need ragel binary. Make sure CMake [find_program](https://cmake.org/cmake/help/latest/command/find_program.html) can find it.
