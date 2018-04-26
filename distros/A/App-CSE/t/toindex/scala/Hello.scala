/**
  * The Hello scala object 
  */

class FooClass{
  def saystuffMethod = println("Stuff")
}

object HelloObject {
  def main(args: Array[String]): Unit = {
    val stuff = new Foo
    println("Hello, world of scala")
    stuff.saystuffMethod
  }
}
