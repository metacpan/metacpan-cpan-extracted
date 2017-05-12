MyObject  *pObj;                      // pointer to an object
LinkedList list;                      // linked list handle

list = LL_new();                      // create new linked list

LL_push(list, NewObject("Foo", 3));   // push a new object onto the list
LL_push(list, NewObject("Bar", 2));   // push a new object onto the list
LL_push(list, NewObject("Cat", 7));   // push a new object onto the list

LL_sort(list, CompareObjects);        // sort the list

printf("The list has %d elements\n",  // print the list's size
       LL_size(list));

LL_foreach(pObj, list)                // loop over all elements
  PrintObject(pObj);

pObj = LL_shift(list);                // shift off the first element
DeleteObject(pObj);                   // ...and delete it

LL_destroy(list, DeleteObject);       // destroy the whole list
