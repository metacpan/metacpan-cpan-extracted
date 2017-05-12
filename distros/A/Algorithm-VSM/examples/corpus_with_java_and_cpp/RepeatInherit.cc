// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 16  Multiple INheritance In C++
//
// Section:     Section 16.8  Implementation Of An Example In Repeated Inheritance
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//RepeatInherit.cc

#include "MI_Utilities.h"
      
//////////////////////////  class Employee  ///////////////////////////
class Employee {
protected:
    string name;
    string address;
    EducationLevel education;
    int yearsExperience;       // years on job
    Department dept;
    PeopleSkill pSkill;        // needed for sales positions
    Leadership leadership;     // needed for management
public:
    Employee( string nam,
              string add,
              EducationLevel edLevel,
              Department depart )
        :     name( nam ),
              address( add ),
              education( edLevel ),
              yearsExperience( 0 ),
              dept( depart ),
              pSkill( pUnknown ),
              leadership( lUnknown ) {}
    // since senior level managers do not belong to any particular
    // department, the next constructor is for such employees:
    Employee( string nam,
              string add,
              EducationLevel edLevel )
        :     name( nam ),
              address( add ),
              education( edLevel ),
              yearsExperience( 0 ),
              pSkill( pUnknown ),
              leadership( lUnknown ) {}
    void setYearsExperience( int yy ) { yearsExperience = yy; }
    void setPeopleSkill( PeopleSkill skill ){ pSkill = skill; }
    string getName() const { return name; }
    string getAddress() const { return address; }
    EducationLevel getEducationLevel() const { return education; }
    virtual void print() {
        cout << name << endl;
        cout << address << endl;
        cout << EducationLevels[ education ] << endl;
        cout << "Years in job: " << yearsExperience << endl;
        cout << "People skill: " << PeopleSkills[ (int) pSkill ] 
             << endl;
        cout << "Leadership quality: " 
             << LeaderQualities[ (int) leadership ]  << endl;
    }
    virtual ~Employee(){}
};

///////////////////////////  class Manager  ///////////////////////////
class Manager : virtual public Employee {                         //(A)
    Department dept;     // note same name as dept in Employee
                         // but different meaning.  Here it is dept 
                         // supervised and not department worked in
protected:
    bool employeeSatisfaction;
    int yearsInManagement;
public:
    Manager( string name,
             string address,
             EducationLevel education,
             Department aDept )
        :    Employee( name, address, education ), 
             dept( aDept ),
             yearsInManagement( 0 ),
             employeeSatisfaction( false ) {}
    // Since senior-level managers do not belong to any particular
    // department, the next constructor is actually for them
    Manager( string name,
             string address,
             EducationLevel education )
        :    Employee( name, address, education ) {}
    virtual double productivityGainYtoY() {                       //(B)
        int lastProd = dept.getProductionLastYear();
        int prevProd = dept.getProductionPreviousYear();
        return 100 * ( lastProd - prevProd ) / (double) prevProd;
    }
    void setDepartment( Department dept ){ this->dept = dept; }
    int getYearsInManagement() { return yearsInManagement; }
    void setYearsInManagement( int y ) { yearsInManagement = y; }
    bool getEmployeeSatisfaction() { return employeeSatisfaction; }
    void setEmployeeSatisfaction( bool satis ) { 
        employeeSatisfaction = satis; 
    }
    virtual bool readyForPromotion(){
        return ( ( yearsInManagement 
                       >= MinYearsForPromotion ) ? true : false )
                 && ( productivityGainYtoY() > 10 ) 
                 && employeeSatisfaction;
    }
    void print() { Employee::print(); dept.print(); }
    ~Manager(){}
};

//////////////////////  class ExecutiveManager  ///////////////////////
// An ExecutiveManager supervises more than one department
class ExecutiveManager : public Manager {
    short level;
    vector<Department> departments;    // depts in charge of
public:
    // no-arg const. needed in the second example for type conversion
    // from Manager to ExecutiveManager:
    ExecutiveManager() 
        :       Manager( "", "", eUnknown ), 
                Employee( "", "", eUnknown ),                     //(C)
                level( 0 ) {}
    ExecutiveManager( string name, 
                      string address, 
                      EducationLevel education,
                      short level )
              :       Manager( name, address, education ), 
                      Employee( name, address, education ),       //(D)
                      level( level )
    {
        departments = vector<Department>();
    }
    void addDepartment(Department dept){departments.push_back( dept );}
    void setLevel( int lvl ) { level = lvl; }
    // overrides Manager's productivityGainYtoY():
    double productivityGainYtoY() {                               //(E)
        double gain = 0.0;
        vector<Department>::iterator iter = departments.begin();
        while ( iter != departments.end() ) {
            int lastProd = iter->getProductionLastYear();
            int prevProd = iter->getProductionPreviousYear();
            gain += ( lastProd - prevProd ) / prevProd;
        }
        return gain/departments.size();
    }
    void print() {
        Employee::print();
        cout << "Departments supervised: " << endl;
        vector<Department>::iterator iter = departments.begin();
        while ( iter != departments.end() ) 
            iter++->print();
    }
    ~ExecutiveManager(){}
};

/////////////////////////  class SalesPerson  /////////////////////////
class SalesPerson : virtual public Employee {                     //(F)
    int salesLastYear;
    int salesPreviousYear;
protected:
    int yearsInSales;
public:
    SalesPerson( string name,
                 string address,
                 EducationLevel education )
        :        Employee( name, 
                           address, 
                           education, 
                           Department( "Sales" )),
                 salesLastYear( 0 ),
                 salesPreviousYear( 0 ),
                 yearsInSales( 0 ) {}
    int getSalesLastYear() {
        return salesLastYear;
    }
    void setSalesLastYear( int sales ) {
        salesLastYear = sales;
    }
    int getSalesPreviousYear() {
        return salesPreviousYear;
    }
    void setSalesPreviousYear( int sales ) {
        salesPreviousYear = sales;
    }
    int getYearsInSales() { return yearsInSales; }
    void setYearsInSales( int y ) { yearsInSales = y; }
    virtual double productivityGainYtoY() {                       //(G)
        return 100 * ( salesLastYear 
            - salesPreviousYear ) / (double) salesPreviousYear;
    }
    virtual bool readyForPromotion(){
        return ( ( yearsInSales 
                       >= MinYearsForPromotion ) ? true : false )
               && ( productivityGainYtoY() > 10 );
    }
    ~SalesPerson(){}
};

////////////////////////  class SalesManager  /////////////////////////
class SalesManager : public SalesPerson, public Manager {
    int yearInSalesManagement;
    vector<SalesPerson> sellersSupervised;
public:
    SalesManager( string name,
                  string address,
                  EducationLevel education )
        :         Manager( name, address, education ),
                  SalesPerson( name, address, education ),
                  Employee( name, address, education ) {}         //(H)
  
    double productivityGainYtoY(){
        return 0;   // left for the reader to complete
    }
    ~SalesManager(){}
};

///////////////////////////////  main  ////////////////////////////////
int main()
{
    Department d1( "Design" );
    d1.setProductionLastYear( 110001 );         // for last year
    d1.setProductionPreviousYear( 100000 );     // for two years back

    Manager manager1("Miz Importante", "UptownUSA", College, d1); //(I)
    manager1.setYearsInManagement( 8 );
    manager1.setEmployeeSatisfaction( true );

    if ( manager1.readyForPromotion() ) {
        cout << manager1.getName() << " "
             << "is ready for promotion." << endl;
    } else {
        cout << manager1.getName() << " "
             << "is not ready for promotion." 
             << endl << endl;
    }

    Department d2( "Manufacturing" );
    Department d3( "Development" );

    SalesPerson salesman("Joe Seller", "DowntownUSA", College);   //(J)
    salesman.setYearsInSales( 5 );
    salesman.setSalesPreviousYear( 100 );
    salesman.setSalesLastYear( 100 );
    if ( salesman.readyForPromotion() ) {
        cout << salesman.getName() << " "
             << "is ready for promotion." << endl;
    } else {
        cout << salesman.getName() << " " 
             << "is not ready for promotion." << endl;
    }    

    ExecutiveManager bigshot( "Zushock Zinger",                   //(K)
                               "MainstreetUSA", CollegePlus, 4 );
    bigshot.addDepartment( d1 );
    bigshot.addDepartment( d2 );
    bigshot.addDepartment( d3 );
    bigshot.print();                                              //(L)

    return 0;
}