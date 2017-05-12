#!/usr/bin/env python
#-*- coding: iso-8859-1 -*-

import os
import sys


def printlist(a):

    for i in a:
        print str(i) + " ",
    print


print "Strings:"

a = "Hello"

if a.endswith("ello"):
    print 'a ends with "ello".'

if "ll" in a:
    print '"ll" is in a.'

a = "2345"

if a.isdigit():
    print 'a is a digit.'

a = "    Line    "

print a.lstrip()
a = a.replace("Line", "Another line")
print a
print a.rstrip()

a = "Hello"

if a.startswith("He"):
    print 'a starts with "He".'

print len(a)

print
print "Lists:"

a = ["a", "b", "c"]
b = "d"

a.append(b)

printlist(a)

a = ["a", "b", "c"]
b = [1, 2, 3]

a.extend(b)

printlist(a)

if "c" in a:
    print '"c" is in @a.'

a.insert(1, "a2")

printlist(a)

print len(a)

a.remove("a2")

printlist(a)

print
print "Dictionaries:"

a = {"a" : 1, "b" : 2, "c" :3}

if a.has_key("c"):
    print 'a has a key "c".'

print
print "File-related:"

if os.path.isdir("/home/user"):
    print "Is directory."

if os.path.isfile("/home/user/myfile"):
    print "Is file."

a = ["a\n", "b\n", "c\n"]

if os.path.isfile("test12345.txt"):

    print 'File "test12345.txt" already exists. Nothing done.'

else:

    fh = file("test12345.txt", "w")
    fh.writelines(a)
    fh.close()

    fh = file("test12345.txt", "r")
    c = fh.readlines()
    fh.close()
   
    for i in c:
        i = i.rstrip()
        print i + " ",
    print

print
print os.listdir(".")

print
print "System-related:"
print os.name

